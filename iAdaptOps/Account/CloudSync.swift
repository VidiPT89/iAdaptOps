import FirebaseFirestore
import Foundation

/// Where a signed-in user's progress is backed up. The view model only talks
/// to this protocol, so tests can swap in an in-memory copy.
@MainActor
protocol CloudSyncing: AnyObject {
    /// Creates the account's profile document the first time, taking the
    /// program from a pending invite for its email, and keeps the name and
    /// email the admin sees up to date.
    func claimProfile(name: String?, email: String?) async throws
    func fetch() async throws -> CloudSnapshot
    func save(state: RemoteState) async throws
    func save(session: RemoteSession) async throws
    func save(health: RemoteHealth) async throws
    func deleteSession(id: String) async throws
    func deleteEverything() async throws
}

/// Firestore layout: `users/{uid}` holds the program settings and
/// `users/{uid}/sessions/{id}` one document per finished workout. The rules in
/// `firebase/firestore.rules` keep each user inside their own branch.
@MainActor
final class FirestoreCloudSync: CloudSyncing {
    private let userDocument: DocumentReference
    private var sessions: CollectionReference { userDocument.collection("sessions") }
    private var healthDocument: DocumentReference { userDocument.collection("private").document("health") }

    /// A first sync should never keep someone staring at a spinner; past this
    /// the app carries on with what is on the device.
    private let fetchTimeout: Duration = .seconds(8)

    init(uid: String) {
        userDocument = Firestore.firestore().collection("users").document(uid)
    }

    func claimProfile(name: String?, email: String?) async throws {
        try await withTimeout(fetchTimeout) { try await self.claim(name: name, email: email) }
    }

    private func claim(name: String?, email: String?) async throws {
        let email = email?.lowercased()
        var fields: [String: Any] = [:]
        if let name { fields["name"] = name }
        if let email { fields["email"] = email }

        let existing = try await userDocument.getDocument()
        if existing.get("programID") == nil, let email {
            let invite = try? await Firestore.firestore().collection("invites").document(email).getDocument()
            if let programID = invite?.get("programID") as? String {
                fields["programID"] = programID
                if name == nil, let invitedName = invite?.get("name") as? String {
                    fields["name"] = invitedName
                }
            }
        }
        // Only write what actually changed, so a normal launch costs one read.
        fields = fields.filter { key, value in
            (existing.get(key) as? String) != (value as? String)
        }
        guard !fields.isEmpty else { return }
        // Not awaited: offline, the write waits in the local cache until the
        // connection returns, and the next read already sees it.
        let document = userDocument
        Task { try? await document.setData(fields, merge: true) }
    }

    func fetch() async throws -> CloudSnapshot {
        try await withTimeout(fetchTimeout) { try await self.load() }
    }

    private func load() async throws -> CloudSnapshot {
        let stateDocument = try await userDocument.getDocument()
        let sessionDocuments = try await sessions.getDocuments()
        let healthData = try await healthDocument.getDocument().data()
        return CloudSnapshot(
            state: stateDocument.data().flatMap(RemoteState.init(fields:)),
            sessions: sessionDocuments.documents.compactMap {
                RemoteSession(id: $0.documentID, fields: $0.data())
            },
            programID: stateDocument.get("programID") as? String,
            health: healthData.flatMap(RemoteHealth.init(fields:))
        )
    }

    func save(state: RemoteState) async throws {
        try await userDocument.setData(state.fields, merge: true)
    }

    func save(session: RemoteSession) async throws {
        try await sessions.document(session.id).setData(session.fields)
    }

    func save(health: RemoteHealth) async throws {
        try await healthDocument.setData(health.fields)
    }

    func deleteSession(id: String) async throws {
        try await sessions.document(id).delete()
    }

    /// Must reach the server: the account is deleted right after, so a write
    /// left queued offline would never be allowed through. Gives up instead
    /// of waiting forever when there is no connection.
    func deleteEverything() async throws {
        try await withTimeout(.seconds(20)) {
            let batch = Firestore.firestore().batch()
            for document in try await self.sessions.getDocuments(source: .server).documents {
                batch.deleteDocument(document.reference)
            }
            batch.deleteDocument(self.healthDocument)
            batch.deleteDocument(self.userDocument)
            try await batch.commit()
        }
    }
}
