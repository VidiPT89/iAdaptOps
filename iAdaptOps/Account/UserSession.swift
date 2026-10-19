import Foundation
import SwiftData

/// Everything that belongs to one signed-in account on this device: its own
/// SwiftData store, so two people sharing a phone never see each other's
/// progress, and the view model that reads it.
@MainActor
final class UserSession {
    let uid: String
    let container: ModelContainer
    let viewModel: ProgramViewModel

    init(user: AccountUser, syncsToCloud: Bool) {
        uid = user.uid
        container = Self.makeContainer(uid: user.uid)
        viewModel = ProgramViewModel()
        viewModel.load(
            context: container.mainContext,
            sync: syncsToCloud ? FirestoreCloudSync(uid: user.uid) : nil,
            name: user.name,
            email: user.email
        )
    }

    private static let schema = Schema([ProgramState.self, CompletedSession.self])

    static func storeDirectory(uid: String) -> URL {
        URL.applicationSupportDirectory
            .appending(path: "Accounts", directoryHint: .isDirectory)
            .appending(path: uid, directoryHint: .isDirectory)
    }

    private static func makeContainer(uid: String) -> ModelContainer {
        let directory = storeDirectory(uid: uid)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let configuration = ModelConfiguration(schema: schema, url: directory.appending(path: "iAdaptOps.store"))
        if let container = try? ModelContainer(for: schema, configurations: configuration) {
            return container
        }
        // An unreadable store must not lock the person out: the cloud copy
        // refills an in-memory store for this launch.
        return try! ModelContainer(
            for: schema,
            configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        )
    }

    /// Removes this account's store from the device, after the account is deleted.
    static func removeLocalData(uid: String) {
        try? FileManager.default.removeItem(at: storeDirectory(uid: uid))
    }
}
