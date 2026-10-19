import Foundation

/// The program settings as stored in the cloud. Dates travel as seconds since
/// 1970 so the mapping stays plain data, independent of the database SDK.
struct RemoteState: Equatable {
    var startDate: Date
    var reminderEnabled: Bool
    var reminderTime: Date?
    var medicalClearance: Bool
    var updatedAt: Date

    init(startDate: Date, reminderEnabled: Bool, reminderTime: Date?, medicalClearance: Bool, updatedAt: Date) {
        self.startDate = startDate
        self.reminderEnabled = reminderEnabled
        self.reminderTime = reminderTime
        self.medicalClearance = medicalClearance
        self.updatedAt = updatedAt
    }

    init?(fields: [String: Any]) {
        guard let start = CloudField.date(fields["startDate"]),
              let updated = CloudField.date(fields["updatedAt"])
        else { return nil }
        startDate = start
        updatedAt = updated
        reminderEnabled = fields["reminderEnabled"] as? Bool ?? false
        reminderTime = CloudField.date(fields["reminderTime"])
        medicalClearance = fields["medicalClearance"] as? Bool ?? false
    }

    var fields: [String: Any] {
        var fields: [String: Any] = [
            "startDate": startDate.timeIntervalSince1970,
            "reminderEnabled": reminderEnabled,
            "medicalClearance": medicalClearance,
            "updatedAt": updatedAt.timeIntervalSince1970
        ]
        if let reminderTime { fields["reminderTime"] = reminderTime.timeIntervalSince1970 }
        return fields
    }
}

/// One finished workout as stored in the cloud, keyed by its own id so the
/// same session is never counted twice across devices.
struct RemoteSession: Equatable {
    var id: String
    var dayIndex: Int
    var date: Date
    var durationSeconds: Int
    var lowEnergy: Bool
    var energy: Int?
    var discomfort: Int?
    var note: String?

    init(
        id: String, dayIndex: Int, date: Date, durationSeconds: Int, lowEnergy: Bool,
        energy: Int? = nil, discomfort: Int? = nil, note: String? = nil
    ) {
        self.id = id
        self.dayIndex = dayIndex
        self.date = date
        self.durationSeconds = durationSeconds
        self.lowEnergy = lowEnergy
        self.energy = energy
        self.discomfort = discomfort
        self.note = note
    }

    init?(id: String, fields: [String: Any]) {
        guard let dayIndex = CloudField.int(fields["dayIndex"]),
              (1...ProgramData.totalDays).contains(dayIndex),
              let date = CloudField.date(fields["date"])
        else { return nil }
        self.id = id
        self.dayIndex = dayIndex
        self.date = date
        durationSeconds = max(0, CloudField.int(fields["durationSeconds"]) ?? 0)
        lowEnergy = fields["lowEnergy"] as? Bool ?? false
        energy = CloudField.int(fields["energy"]).map { min(max($0, 1), 5) }
        discomfort = CloudField.int(fields["discomfort"]).map { min(max($0, 0), 10) }
        note = fields["note"] as? String
    }

    var fields: [String: Any] {
        var fields: [String: Any] = [
            "dayIndex": dayIndex,
            "date": date.timeIntervalSince1970,
            "durationSeconds": durationSeconds,
            "lowEnergy": lowEnergy
        ]
        if let energy { fields["energy"] = energy }
        if let discomfort { fields["discomfort"] = discomfort }
        if let note { fields["note"] = note }
        return fields
    }
}

struct CloudSnapshot: Equatable {
    var state: RemoteState?
    var sessions: [RemoteSession]
    /// Set by the admin or an invite, never written by the app itself, so it
    /// travels apart from the settings the user can change.
    var programID: String?
    /// The questionnaire answers from the account's private document.
    var health: RemoteHealth?

    init(state: RemoteState?, sessions: [RemoteSession], programID: String? = nil, health: RemoteHealth? = nil) {
        self.state = state
        self.sessions = sessions
        self.programID = programID
        self.health = health
    }
}

/// The questionnaire answers, kept in `users/{uid}/private/health`, which
/// only the owner can read: not even the admin sees health details.
struct RemoteHealth: Equatable {
    /// `HealthProfile` as JSON.
    var profile: String
    var updatedAt: Date

    init(profile: String, updatedAt: Date) {
        self.profile = profile
        self.updatedAt = updatedAt
    }

    init?(fields: [String: Any]) {
        guard let profile = fields["profile"] as? String,
              profile.count <= 4000,
              (try? HealthProfile(json: profile)) != nil,
              let updatedAt = CloudField.date(fields["updatedAt"])
        else { return nil }
        self.profile = profile
        self.updatedAt = updatedAt
    }

    var fields: [String: Any] {
        ["profile": profile, "updatedAt": updatedAt.timeIntervalSince1970]
    }
}

/// Reads numbers defensively: the database hands them back as NSNumber of
/// whichever width it chose.
private enum CloudField {
    static func date(_ value: Any?) -> Date? {
        (value as? NSNumber).map { Date(timeIntervalSince1970: $0.doubleValue) }
    }

    static func int(_ value: Any?) -> Int? {
        (value as? NSNumber)?.intValue
    }
}

extension RemoteState {
    init(_ state: ProgramState) {
        self.init(
            startDate: state.startDate,
            reminderEnabled: state.reminderEnabled,
            reminderTime: state.reminderTime,
            medicalClearance: state.medicalClearance,
            updatedAt: state.updatedAt
        )
    }
}

extension RemoteSession {
    init(_ session: CompletedSession) {
        self.init(
            id: session.uuid,
            dayIndex: session.dayIndex,
            date: session.date,
            durationSeconds: session.durationSeconds,
            lowEnergy: session.lowEnergy,
            energy: session.energy,
            discomfort: session.discomfort,
            note: session.note
        )
    }
}
