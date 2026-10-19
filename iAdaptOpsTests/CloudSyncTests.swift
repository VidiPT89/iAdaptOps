import SwiftData
import XCTest
@testable import iAdaptOps

/// In-memory stand-in for the cloud, so the merge rules can be tested
/// without a network or a Firebase project.
@MainActor
private final class FakeCloud: CloudSyncing {
    var state: RemoteState?
    var sessions: [String: RemoteSession] = [:]
    var isReachable = true
    var programID: String?
    var invitedProgramID: String?
    var profileName: String?
    var health: RemoteHealth?

    func claimProfile(name: String?, email: String?) async throws {
        guard isReachable else { throw URLError(.notConnectedToInternet) }
        profileName = name ?? profileName
        if programID == nil { programID = invitedProgramID }
    }

    func fetch() async throws -> CloudSnapshot {
        guard isReachable else { throw URLError(.notConnectedToInternet) }
        return CloudSnapshot(state: state, sessions: Array(sessions.values), programID: programID, health: health)
    }

    func save(state: RemoteState) async throws { self.state = state }
    func save(session: RemoteSession) async throws { sessions[session.id] = session }
    func save(health: RemoteHealth) async throws { self.health = health }
    func deleteSession(id: String) async throws { sessions[id] = nil }

    func deleteEverything() async throws {
        state = nil
        sessions = [:]
        health = nil
    }
}

@MainActor
final class CloudSyncTests: XCTestCase {
    private func makeDevice(_ cloud: FakeCloud) throws -> ProgramViewModel {
        let container = try ModelContainer(
            for: ProgramState.self, CompletedSession.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let viewModel = ProgramViewModel()
        viewModel.load(context: ModelContext(container), sync: cloud)
        return viewModel
    }

    /// Lets the fire-and-forget uploads started by a mutation finish.
    private func settle() async {
        for _ in 0..<5 { await Task.yield() }
    }

    private var day1: ProgramDay { ProgramData.days.first(where: { $0.index == 1 })! }
    private var day2: ProgramDay { ProgramData.days.first(where: { $0.index == 2 })! }

    // MARK: - Merging

    func testANewPhoneRestoresTheProgramAndHistoryFromTheCloud() async throws {
        let cloud = FakeCloud()
        let first = try makeDevice(cloud)
        first.startProgram(startDate: Date(), reminderTime: nil, medicalClearance: true)
        first.complete(day: day1, durationSeconds: 1_000, lowEnergy: true, energy: 4)
        await settle()

        let second = try makeDevice(cloud)
        XCTAssertFalse(second.hasOnboarded)
        await second.synchronize()

        XCTAssertTrue(second.hasOnboarded)
        XCTAssertEqual(second.completedDayIndices, [1])
        XCTAssertEqual(second.sessions.first?.energy, 4)
        XCTAssertEqual(second.sessions.first?.lowEnergy, true)
    }

    func testWorkoutsLoggedOfflineAreUploadedOnTheNextSync() async throws {
        let cloud = FakeCloud()
        cloud.isReachable = false
        let phone = try makeDevice(cloud)
        phone.startProgram(startDate: Date(), reminderTime: nil, medicalClearance: true)
        await phone.synchronize()

        cloud.isReachable = true
        cloud.sessions = [:]
        phone.complete(day: day1, durationSeconds: 900, lowEnergy: false)
        cloud.sessions = [:]  // pretend the live upload never arrived

        await phone.synchronize()
        await settle()

        XCTAssertEqual(cloud.sessions.count, 1)
        XCTAssertEqual(cloud.sessions.values.first?.dayIndex, 1)
    }

    func testAWorkoutDeletedOnAnotherPhoneDisappearsHereToo() async throws {
        let cloud = FakeCloud()
        let first = try makeDevice(cloud)
        first.startProgram(startDate: Date(), reminderTime: nil, medicalClearance: true)
        first.complete(day: day1, durationSeconds: 900, lowEnergy: false)
        first.complete(day: day2, durationSeconds: 900, lowEnergy: false)
        await settle()

        let second = try makeDevice(cloud)
        await second.synchronize()
        XCTAssertEqual(second.completedCount, 2)

        let dayOne = try XCTUnwrap(first.sessions.first { $0.dayIndex == 1 })
        first.delete(dayOne)
        await settle()

        await second.synchronize()
        XCTAssertEqual(second.completedDayIndices, [2])
    }

    func testTheMostRecentSettingsChangeWins() async throws {
        let cloud = FakeCloud()
        let phone = try makeDevice(cloud)
        phone.startProgram(startDate: Date(), reminderTime: nil, medicalClearance: true)
        await settle()

        let later = Calendar.current.date(byAdding: .day, value: 14, to: Date())!
        var newer = try XCTUnwrap(cloud.state)
        newer.startDate = Calendar.current.startOfDay(for: later)
        newer.updatedAt = Date().addingTimeInterval(60)
        cloud.state = newer

        await phone.synchronize()
        XCTAssertEqual(phone.state?.startDate, newer.startDate)
    }

    func testNothingChangesLocallyWhenTheCloudIsUnreachable() async throws {
        let cloud = FakeCloud()
        let phone = try makeDevice(cloud)
        phone.startProgram(startDate: Date(), reminderTime: nil, medicalClearance: true)
        phone.complete(day: day1, durationSeconds: 900, lowEnergy: false)
        await settle()

        cloud.isReachable = false
        cloud.sessions = [:]
        await phone.synchronize()

        XCTAssertEqual(phone.completedCount, 1)
    }

    func testRestartingTheProgramClearsTheCloudHistory() async throws {
        let cloud = FakeCloud()
        let phone = try makeDevice(cloud)
        phone.startProgram(startDate: Date(), reminderTime: nil, medicalClearance: true)
        phone.complete(day: day1, durationSeconds: 900, lowEnergy: false)
        await settle()
        XCTAssertEqual(cloud.sessions.count, 1)

        phone.restartProgram()
        await settle()

        XCTAssertTrue(cloud.sessions.isEmpty)
    }

    // MARK: - Assigned program

    func testAnInvitedProgramIsInPlaceBeforeOnboarding() async throws {
        let cloud = FakeCloud()
        cloud.invitedProgramID = ProgramVariant.anaChallenge.rawValue
        let phone = try makeDevice(cloud)

        await phone.synchronize()
        XCTAssertEqual(phone.variant, .anaChallenge)

        phone.startProgram(startDate: Date(), reminderTime: nil, medicalClearance: true)
        XCTAssertEqual(phone.state?.programID, ProgramVariant.anaChallenge.rawValue)
        XCTAssertEqual(phone.day(at: 3)?.cooldown.map(\.ref.exercise), [.childsPose, .hipFlexorStretch])
    }

    func testTheAdminCanSwitchAProgramLater() async throws {
        let cloud = FakeCloud()
        let phone = try makeDevice(cloud)
        phone.startProgram(startDate: Date(), reminderTime: nil, medicalClearance: true)
        await phone.synchronize()
        XCTAssertEqual(phone.variant, .personalized)

        cloud.programID = ProgramVariant.anaChallenge.rawValue
        await phone.synchronize()
        XCTAssertEqual(phone.variant, .anaChallenge)
    }

    func testOnlyTheVerifiedAdminEmailIsAdmin() {
        let admin = AccountUser(uid: "a", name: "Vidi", email: "iVidi.dev@gmail.com", providerIDs: ["google.com"], isEmailVerified: true)
        XCTAssertTrue(admin.isAdmin)
        let personal = AccountUser(uid: "c", name: "David", email: "damartins89@gmail.com", providerIDs: ["google.com"], isEmailVerified: true)
        XCTAssertFalse(personal.isAdmin)
        let unverified = AccountUser(uid: "a", name: nil, email: AdminPolicy.email, providerIDs: ["password"], isEmailVerified: false)
        XCTAssertFalse(unverified.isAdmin)
        let ana = AccountUser(uid: "b", name: "Ana", email: "anacatarinasveiga@gmail.com", providerIDs: ["password"], isEmailVerified: true)
        XCTAssertFalse(ana.isAdmin)
    }

    // MARK: - Records

    func testRecordsSurviveARoundTripThroughPlainFields() throws {
        let session = RemoteSession(
            id: "abc", dayIndex: 7, date: Date(timeIntervalSince1970: 1_800_000_000),
            durationSeconds: 1_140, lowEnergy: true, energy: 3, discomfort: 2, note: "Joelho bem"
        )
        let numbers = session.fields.mapValues { value -> Any in
            // The database hands numbers back as NSNumber.
            (value as? Int).map { NSNumber(value: $0) } ?? (value as? Double).map { NSNumber(value: $0) } ?? value
        }
        XCTAssertEqual(RemoteSession(id: "abc", fields: numbers), session)

        let state = RemoteState(
            startDate: Date(timeIntervalSince1970: 1_790_000_000), reminderEnabled: true,
            reminderTime: Date(timeIntervalSince1970: 1_790_030_000), medicalClearance: true,
            updatedAt: Date(timeIntervalSince1970: 1_790_050_000)
        )
        let stateNumbers = state.fields.mapValues { ($0 as? Double).map { NSNumber(value: $0) } ?? $0 }
        XCTAssertEqual(RemoteState(fields: stateNumbers), state)
    }

    /// Mirrors `validProfile` and `validSession` in firebase/firestore.rules:
    /// if the app ever sends a field the rules do not allow, every write fails.
    func testRecordsOnlyUseFieldsTheSecurityRulesAccept() {
        let profileFields: Set<String> = [
            "name", "email", "programID", "startDate", "reminderEnabled",
            "reminderTime", "medicalClearance", "updatedAt"
        ]
        let sessionFields: Set<String> = [
            "dayIndex", "date", "durationSeconds", "lowEnergy", "energy", "discomfort", "note"
        ]
        let state = RemoteState(
            startDate: Date(), reminderEnabled: true, reminderTime: Date(),
            medicalClearance: true, updatedAt: Date()
        )
        XCTAssertTrue(Set(state.fields.keys).isSubset(of: profileFields))
        XCTAssertNil(state.fields["programID"], "Only the admin or an invite sets the program")

        let session = RemoteSession(
            id: "x", dayIndex: 1, date: Date(), durationSeconds: 1, lowEnergy: false,
            energy: 1, discomfort: 0, note: "n"
        )
        XCTAssertTrue(Set(session.fields.keys).isSubset(of: sessionFields))
        XCTAssertTrue(session.fields["dayIndex"] is Int)
        XCTAssertLessThanOrEqual(SessionCompleteView.noteLimit, 500)
    }

    func testTimeoutGivesUpOnWorkThatNeverStops() async {
        let start = Date()
        do {
            _ = try await withTimeout(.milliseconds(200)) {
                // Ignores cancellation, like the database SDK does.
                try? await Task.sleep(for: .seconds(5))
                return 1
            }
            XCTFail("Should have timed out")
        } catch {
            XCTAssertTrue(error is CancellationError)
        }
        XCTAssertLessThan(Date().timeIntervalSince(start), 2)

        let value = try? await withTimeout(.seconds(2)) { 42 }
        XCTAssertEqual(value, 42)
    }

    func testMalformedCloudRecordsAreIgnored() {
        XCTAssertNil(RemoteSession(id: "x", fields: ["dayIndex": NSNumber(value: 99), "date": NSNumber(value: 1)]))
        XCTAssertNil(RemoteSession(id: "x", fields: ["dayIndex": NSNumber(value: 3)]))
        XCTAssertNil(RemoteState(fields: ["reminderEnabled": true]))

        let clamped = RemoteSession(id: "x", fields: [
            "dayIndex": NSNumber(value: 3), "date": NSNumber(value: 1), "energy": NSNumber(value: 9)
        ])
        XCTAssertEqual(clamped?.energy, 5)
    }

    // MARK: - Sign-in form

    func testFormValidationCatchesTheCommonMistakes() {
        XCTAssertEqual(AuthValidation.problemKey(name: " ", email: "a@b.pt", password: "secret1"), "auth.error.nameMissing")
        XCTAssertEqual(AuthValidation.problemKey(name: nil, email: "ana@", password: "secret1"), "auth.error.invalidEmail")
        XCTAssertEqual(AuthValidation.problemKey(name: nil, email: "ana@mail.pt", password: "12345"), "auth.error.weakPassword")
        XCTAssertNil(AuthValidation.problemKey(name: "Ana", email: " ana@mail.pt ", password: "123456"))
        XCTAssertNil(AuthValidation.problemKey(name: nil, email: "ana.silva+treino@mail.co.uk", password: "123456"))
    }

    func testAccountShowsTheFirstNameAndHowItSignsIn() {
        let user = AccountUser(uid: "1", name: "Ana Maria Silva", email: "ana@mail.pt", providerIDs: ["google.com"])
        XCTAssertEqual(user.firstName, "Ana")
        XCTAssertEqual(user.providerLabelKey, "auth.provider.google")
        XCTAssertEqual(
            AccountUser(uid: "2", name: nil, email: "x@y.pt", providerIDs: ["password"]).providerLabelKey,
            "auth.provider.email"
        )
    }
}

final class AuthErrorDetailsTests: XCTestCase {
    func testRecognisesTheServerSayingAuthenticationIsOff() {
        let server = NSError(domain: "FIRAuthInternalErrorDomain", code: 3, userInfo: [
            "FIRAuthErrorUserInfoDeserializedResponseKey": ["message": "CONFIGURATION_NOT_FOUND", "code": 400]
        ])
        let wrapped = NSError(domain: "FIRAuthErrorDomain", code: 17999, userInfo: [NSUnderlyingErrorKey: server])
        XCTAssertTrue(AuthErrorDetails.isServiceNotConfigured(wrapped))
        XCTAssertFalse(AuthErrorDetails.isServiceNotConfigured(NSError(domain: "FIRAuthErrorDomain", code: 17009)))
    }
}
