import Foundation

/// What the home-screen widget shows, written by the app into the shared App
/// Group and read by the widget extension, which cannot open the app's
/// database. Texts that come from the big translation table are stored
/// already translated; the widget's own few labels live in `WidgetText`.
struct WidgetSnapshot: Codable, Equatable {
    var language: String
    var completed: Int
    var total: Int
    var startDate: Date?
    var lastWorkoutDate: Date?
    var next: NextWorkout?

    struct NextWorkout: Codable, Equatable {
        let dayIndex: Int
        let week: Int
        let title: String
        let minutes: Int
    }

    enum Status: Equatable {
        case noProgram
        case complete
        case startsIn(days: Int)
        case doneToday
        case restDay
        case workout
    }

    /// Mirrors what the Today screen shows, for any moment, so the widget can
    /// schedule tomorrow's state in advance.
    func status(at date: Date, calendar: Calendar = .current) -> Status {
        if total > 0, completed >= total { return .complete }
        guard let startDate else { return .noProgram }
        let today = calendar.startOfDay(for: date)
        let daysToStart = calendar.dateComponents([.day], from: today, to: calendar.startOfDay(for: startDate)).day ?? 0
        if daysToStart > 0 { return .startsIn(days: daysToStart) }
        if let lastWorkoutDate, calendar.isDate(lastWorkoutDate, inSameDayAs: date) { return .doneToday }
        // Friday, Saturday and Sunday are rest days.
        if [6, 7, 1].contains(calendar.component(.weekday, from: date)) { return .restDay }
        return next == nil ? .complete : .workout
    }

    var progress: Double { total > 0 ? min(1, Double(completed) / Double(total)) : 0 }

    // MARK: - Storage

    static let appGroup = "group.dev.ividi.iadaptops"
    private static let key = "widgetSnapshot"

    static func load() -> WidgetSnapshot? {
        guard let data = UserDefaults(suiteName: appGroup)?.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
    }

    /// Returns false when nothing changed, so the caller can skip reloading
    /// the widget.
    @discardableResult
    static func save(_ snapshot: WidgetSnapshot?) -> Bool {
        guard let defaults = UserDefaults(suiteName: appGroup) else { return false }
        let data = snapshot.flatMap { try? JSONEncoder().encode($0) }
        guard data != defaults.data(forKey: key) else { return false }
        defaults.set(data, forKey: key)
        return true
    }
}

/// The widget's own labels, in both of the app's languages.
enum WidgetText {
    static func text(_ key: String, _ language: String) -> String {
        let isPortuguese = language != "en"
        switch key {
        case "workout": return isPortuguese ? "Treino de hoje" : "Today's workout"
        case "restDay": return isPortuguese ? "Dia de descanso" : "Rest day"
        case "doneToday": return isPortuguese ? "Feito hoje" : "Done today"
        case "complete": return isPortuguese ? "Programa completo" : "Program complete"
        case "startsTomorrow": return isPortuguese ? "Começa amanhã" : "Starts tomorrow"
        case "startsIn": return isPortuguese ? "Começa em %d dias" : "Starts in %d days"
        case "upNext": return isPortuguese ? "A seguir" : "Up next"
        case "day": return isPortuguese ? "Dia %d" : "Day %d"
        case "week": return isPortuguese ? "Semana %d" : "Week %d"
        case "noProgram": return isPortuguese ? "Abre a app para começar" : "Open the app to begin"
        case "sessions": return isPortuguese ? "sessões" : "sessions"
        case "description": return isPortuguese
            ? "O treino de hoje e o teu progresso."
            : "Today's workout and your progress."
        default: return key
        }
    }

    static func text(_ key: String, _ language: String, _ value: Int) -> String {
        String(format: text(key, language), value)
    }
}
