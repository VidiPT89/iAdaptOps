import Foundation
import SwiftData

/// Keeps the device's copy of the program and the account's cloud copy in
/// step. The device is always usable on its own; the cloud is merged in when
/// it can be reached, and every change is sent up as it happens.
extension ProgramViewModel {
    /// Pulls the cloud copy and merges it with this device:
    /// - settings: the side changed most recently wins;
    /// - workouts: new ones from either side are kept, and a workout this
    ///   device had already synced but the cloud no longer has was deleted
    ///   elsewhere, so it goes here too.
    /// When the cloud cannot be reached nothing changes locally.
    func synchronize() async {
        guard let sync, let context else { return }
        try? await sync.claimProfile(name: profile.name, email: profile.email)
        guard let snapshot = try? await sync.fetch() else { return }

        mergeState(snapshot.state, into: context)
        mergeSessions(snapshot.sessions, into: context)
        applyAssignedProgram(snapshot.programID, in: context)
        mergeHealth(snapshot.health, in: context)

        try? context.save()
        refresh()
    }

    private func mergeState(_ remote: RemoteState?, into context: ModelContext) {
        switch (state, remote) {
        case (nil, let remote?):
            context.insert(ProgramState(
                startDate: remote.startDate,
                reminderTime: remote.reminderTime,
                reminderEnabled: remote.reminderEnabled,
                medicalClearance: remote.medicalClearance,
                updatedAt: remote.updatedAt
            ))
        case (let local?, let remote?) where remote.updatedAt > local.updatedAt:
            local.startDate = remote.startDate
            local.reminderTime = remote.reminderTime
            local.reminderEnabled = remote.reminderEnabled
            local.medicalClearance = remote.medicalClearance
            local.updatedAt = remote.updatedAt
        case (let local?, let remote) where remote == nil || local.updatedAt > remote!.updatedAt:
            pushState()
        default:
            break
        }
    }

    /// The assigned program always comes from the cloud: only the admin or
    /// an invite can change it.
    private func applyAssignedProgram(_ programID: String?, in context: ModelContext) {
        guard let programID else { return }
        assignedProgramID = programID
        if let local = (try? context.fetch(FetchDescriptor<ProgramState>()))?.first {
            local.programID = programID
        }
    }

    /// Questionnaire answers: the side answered most recently wins.
    private func mergeHealth(_ remote: RemoteHealth?, in context: ModelContext) {
        guard let local = (try? context.fetch(FetchDescriptor<ProgramState>()))?.first else {
            pendingHealthJSON = remote?.profile
            return
        }
        switch (local.healthUpdatedAt, remote) {
        case (_, let remote?) where local.healthUpdatedAt == nil || remote.updatedAt > local.healthUpdatedAt!:
            local.healthProfileJSON = remote.profile
            local.healthUpdatedAt = remote.updatedAt
        case (let localDate?, let remote) where remote == nil || localDate > remote!.updatedAt:
            pushHealth()
        default:
            break
        }
    }

    private func mergeSessions(_ remote: [RemoteSession], into context: ModelContext) {
        let remoteIDs = Set(remote.map(\.id))
        let localIDs = Set(sessions.map(\.uuid))

        for record in remote where !localIDs.contains(record.id) {
            context.insert(CompletedSession(
                uuid: record.id,
                isSynced: true,
                dayIndex: record.dayIndex,
                date: record.date,
                durationSeconds: record.durationSeconds,
                lowEnergy: record.lowEnergy,
                energy: record.energy,
                discomfort: record.discomfort,
                note: record.note
            ))
        }

        for local in sessions {
            if remoteIDs.contains(local.uuid) {
                local.isSynced = true
            } else if local.isSynced {
                context.delete(local)
            } else {
                push(local)
            }
        }
    }

    // MARK: - Sending changes up

    func pushState() {
        guard let sync, let state else { return }
        let record = RemoteState(state)
        Task { try? await sync.save(state: record) }
    }

    func pushHealth() {
        guard let sync, let json = state?.healthProfileJSON, let date = state?.healthUpdatedAt else { return }
        let record = RemoteHealth(profile: json, updatedAt: date)
        Task { try? await sync.save(health: record) }
    }

    func push(_ session: CompletedSession) {
        guard let sync else { return }
        let record = RemoteSession(session)
        Task {
            guard (try? await sync.save(session: record)) != nil else { return }
            // Looked up again: the row may have been deleted meanwhile.
            if let saved = sessions.first(where: { $0.uuid == record.id }) {
                saved.isSynced = true
                try? context?.save()
            }
        }
    }

    func removeRemoteSessions(_ ids: [String]) {
        guard let sync, !ids.isEmpty else { return }
        Task {
            for id in ids {
                try? await sync.deleteSession(id: id)
            }
        }
    }

    /// Erases the account's cloud copy, used right before deleting the account.
    func deleteCloudData() async throws {
        try await sync?.deleteEverything()
    }
}
