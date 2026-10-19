import FirebaseFirestore
import Foundation

/// One account as the admin sees it in the panel.
struct AdminUserSummary: Identifiable, Equatable {
    let id: String
    var name: String?
    var email: String?
    var variant: ProgramVariant
    var startDate: Date?
    var sessions: [RemoteSession]

    var completedDays: Int { Set(sessions.map(\.dayIndex)).count }
    var lastWorkout: Date? { sessions.map(\.date).max() }

    /// Most recent first, as the history screen shows it.
    var sortedSessions: [RemoteSession] { sessions.sorted { $0.date > $1.date } }
}

/// A profile prepared ahead of time: when someone first signs in with this
/// email, their account starts on the chosen program.
struct AdminInvite: Identifiable, Equatable {
    var id: String { email }
    let email: String
    var name: String?
    var variant: ProgramVariant
}

/// Reads every account and manages invites. Only works for the admin: the
/// database rules refuse these reads and writes for everyone else.
@MainActor
@Observable
final class AdminService {
    private(set) var users: [AdminUserSummary] = []
    private(set) var invites: [AdminInvite] = []
    private(set) var isLoading = false
    var errorKey: String?

    private var database: Firestore { Firestore.firestore() }

    func load() async {
        isLoading = true
        errorKey = nil
        defer { isLoading = false }
        do {
            let userDocuments = try await database.collection("users").getDocuments().documents
            var loaded: [AdminUserSummary] = []
            for document in userDocuments {
                let sessions = try await document.reference.collection("sessions").getDocuments().documents
                loaded.append(AdminUserSummary(
                    id: document.documentID,
                    name: document.get("name") as? String,
                    email: document.get("email") as? String,
                    variant: ProgramVariant(id: document.get("programID") as? String),
                    startDate: RemoteState(fields: document.data())?.startDate,
                    sessions: sessions.compactMap { RemoteSession(id: $0.documentID, fields: $0.data()) }
                ))
            }
            users = loaded.sorted { ($0.lastWorkout ?? .distantPast) > ($1.lastWorkout ?? .distantPast) }

            let inviteDocuments = try await database.collection("invites").getDocuments().documents
            let joined = Set(users.compactMap { $0.email?.lowercased() })
            invites = inviteDocuments
                .map { AdminInvite(
                    email: $0.documentID,
                    name: $0.get("name") as? String,
                    variant: ProgramVariant(id: $0.get("programID") as? String)
                ) }
                .filter { !joined.contains($0.email) }
                .sorted { $0.email < $1.email }
        } catch {
            errorKey = "admin.error.load"
        }
    }

    func setVariant(_ variant: ProgramVariant, for userID: String) async {
        do {
            try await database.collection("users").document(userID)
                .setData(["programID": variant.rawValue], merge: true)
            if let index = users.firstIndex(where: { $0.id == userID }) {
                users[index].variant = variant
            }
        } catch {
            errorKey = "admin.error.save"
        }
    }

    func saveInvite(email: String, name: String?, variant: ProgramVariant) async -> Bool {
        let email = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard AuthValidation.isValidEmail(email) else {
            errorKey = "auth.error.invalidEmail"
            return false
        }
        var fields: [String: Any] = ["programID": variant.rawValue]
        if let name, !name.isEmpty { fields["name"] = name }
        do {
            try await database.collection("invites").document(email).setData(fields)
            invites.removeAll { $0.email == email }
            invites.append(AdminInvite(email: email, name: name, variant: variant))
            invites.sort { $0.email < $1.email }
            return true
        } catch {
            errorKey = "admin.error.save"
            return false
        }
    }

    func deleteInvite(_ invite: AdminInvite) async {
        do {
            try await database.collection("invites").document(invite.email).delete()
            invites.removeAll { $0 == invite }
        } catch {
            errorKey = "admin.error.save"
        }
    }
}
