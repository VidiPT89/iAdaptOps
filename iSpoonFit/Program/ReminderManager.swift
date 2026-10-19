import Foundation
import UserNotifications

/// Local-only workout reminders. Nothing leaves the device: these are
/// scheduled by iOS and delivered by iOS.
@MainActor
enum ReminderManager {
    /// Calendar weekday numbers (1 = Sunday ... 7 = Saturday) in the order the
    /// week is shown, Monday first.
    static let weekOrder = [2, 3, 4, 5, 6, 7, 1]

    /// Monday to Thursday, the training days.
    static let defaultWeekdays: Set<Int> = [2, 3, 4, 5]

    private static let identifierPrefix = "ispoonfit.reminder."
    private static let weekdaysKey = "reminderWeekdays"

    /// The days the user wants to be reminded on. Never empty.
    static var weekdays: Set<Int> {
        get {
            let stored = UserDefaults.standard.array(forKey: weekdaysKey) as? [Int] ?? []
            let valid = Set(stored.filter { (1...7).contains($0) })
            return valid.isEmpty ? defaultWeekdays : valid
        }
        set {
            let value = newValue.isEmpty ? defaultWeekdays : newValue
            UserDefaults.standard.set(value.sorted(), forKey: weekdaysKey)
        }
    }

    static func weekdayKey(_ weekday: Int) -> String {
        ["weekday.sun", "weekday.mon", "weekday.tue", "weekday.wed",
         "weekday.thu", "weekday.fri", "weekday.sat"][(weekday - 1) % 7]
    }

    static func requestAuthorization() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound])
        } catch {
            return false
        }
    }

    static func cancelAll() {
        let identifiers = (1...7).map { identifierPrefix + String($0) }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    /// Replaces any pending reminders. Returns false when the user has not
    /// allowed notifications, so the caller can switch the setting back off.
    @discardableResult
    static func schedule(at time: Date, calendar: Calendar = .current) async -> Bool {
        cancelAll()
        guard await requestAuthorization() else { return false }

        let components = calendar.dateComponents([.hour, .minute], from: time)
        let content = UNMutableNotificationContent()
        content.title = t("reminder.title")
        content.body = t("reminder.body")
        content.sound = .default

        let center = UNUserNotificationCenter.current()
        for weekday in weekdays.sorted() {
            var trigger = DateComponents()
            trigger.weekday = weekday
            trigger.hour = components.hour
            trigger.minute = components.minute

            let request = UNNotificationRequest(
                identifier: identifierPrefix + String(weekday),
                content: content,
                trigger: UNCalendarNotificationTrigger(dateMatching: trigger, repeats: true)
            )
            try? await center.add(request)
        }
        return true
    }
}
