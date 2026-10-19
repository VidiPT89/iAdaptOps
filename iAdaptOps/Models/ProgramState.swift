import Foundation
import SwiftData

/// The single row that records when the program started and how the user
/// wants to be reminded. Its existence is also what marks onboarding as done.
@Model
final class ProgramState {
    var startDate: Date
    var reminderTime: Date?
    var reminderEnabled: Bool
    var medicalClearance: Bool
    /// Bumped on every change; the newer side wins when devices disagree.
    var updatedAt: Date = Date.now
    /// The program variant this account follows. Only the admin (or an
    /// invite) sets it; the app just reads it from the cloud.
    var programID: String = ProgramVariant.personalized.rawValue
    /// The start-up questionnaire as JSON (`HealthProfile`), and when it was
    /// last answered. Synced to a private document only the owner can read.
    var healthProfileJSON: String? = nil
    var healthUpdatedAt: Date? = nil

    init(
        startDate: Date,
        reminderTime: Date? = nil,
        reminderEnabled: Bool = false,
        medicalClearance: Bool = false,
        updatedAt: Date = .now
    ) {
        self.startDate = startDate
        self.reminderTime = reminderTime
        self.reminderEnabled = reminderEnabled
        self.medicalClearance = medicalClearance
        self.updatedAt = updatedAt
    }

    /// The first Monday strictly after `date`: the default start, which always
    /// leaves at least a day to get the mat and the chair ready.
    static func nextMonday(after date: Date = Date(), calendar: Calendar = .current) -> Date {
        let start = calendar.startOfDay(for: date)
        let weekday = calendar.component(.weekday, from: start)
        // Calendar weekday is 1 = Sunday ... 7 = Saturday.
        let daysUntilMonday = (9 - weekday) % 7
        let offset = daysUntilMonday == 0 ? 7 : daysUntilMonday
        return calendar.date(byAdding: .day, value: offset, to: start) ?? start
    }
}
