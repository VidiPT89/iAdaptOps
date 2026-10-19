import XCTest
@testable import iAdaptOps

/// Ana's challenge must match her written plan exactly.
final class ProgramVariantTests: XCTestCase {
    private let ana = ProgramVariant.anaChallenge

    private func stretches(_ day: Int) -> [ExerciseID] {
        ana.days(profile: nil)[day - 1].cooldown.map(\.ref.exercise)
    }

    private func seconds(_ day: Int) -> [Int] {
        ana.days(profile: nil)[day - 1].cooldown.map(\.seconds)
    }

    func testWorkoutsAreTheSameAsTheStandardProgram() {
        XCTAssertEqual(ana.days(profile: nil).count, 28)
        for (mine, standard) in zip(ana.days(profile: nil), ProgramData.days) {
            XCTAssertEqual(mine.index, standard.index)
            XCTAssertEqual(mine.titleKey, standard.titleKey)
            XCTAssertEqual(mine.exercises, standard.exercises, "Day \(mine.index)")
        }
    }

    func testWeekOneHasItsOwnPairOfOneMinuteStretchesEachDay() {
        XCTAssertEqual(stretches(1), [.childsPose, .hamstringStretch])
        XCTAssertEqual(stretches(2), [.figureFour, .quadStretch])
        XCTAssertEqual(stretches(3), [.childsPose, .hipFlexorStretch])
        XCTAssertEqual(stretches(4), [.sideStretch, .hamstringStretch])
        for day in 1...4 {
            XCTAssertEqual(seconds(day), [60, 60], "Day \(day)")
        }
    }

    func testFromDayFiveStretchesAreHeldThirtySecondsPerSide() {
        for day in 5...27 {
            XCTAssertEqual(stretches(day), [.childsPose, .figureFour, .quadStretch, .hamstringStretch], "Day \(day)")
            XCTAssertEqual(seconds(day), [30, 60, 60, 60], "Day \(day)")
        }
    }

    func testTheFinalDayEndsWithTwoMinutesOfStretching() {
        XCTAssertEqual(seconds(28).reduce(0, +), 120)
        XCTAssertEqual(stretches(28), [.childsPose, .figureFour, .quadStretch, .hamstringStretch])
    }

    func testTwoSidedStretchesSwitchHalfway() {
        let steps = SessionBuilder.steps(for: ana.days(profile: nil)[4])
        let figureFour = steps.first { $0.block == .cooldown && $0.ref.exercise == .figureFour }
        XCTAssertEqual(figureFour?.switchSideAtSecond, 30)
        let hipFlexor = SessionBuilder.steps(for: ana.days(profile: nil)[2]).first { $0.ref.exercise == .hipFlexorStretch }
        XCTAssertEqual(hipFlexor?.switchSideAtSecond, 30)
    }

    func testTheSourceProgramKeepsItsTwoMinuteRoutine() {
        for day in ProgramData.days {
            XCTAssertEqual(day.cooldown, ProgramData.cooldown)
        }
    }

    func testUnknownProgramIDsFallBackToPersonalized() {
        XCTAssertEqual(ProgramVariant(id: nil), .personalized)
        XCTAssertEqual(ProgramVariant(id: "standard"), .personalized)
        XCTAssertEqual(ProgramVariant(id: "something-else"), .personalized)
        XCTAssertEqual(ProgramVariant(id: "anaChallenge"), .anaChallenge)
    }
}
