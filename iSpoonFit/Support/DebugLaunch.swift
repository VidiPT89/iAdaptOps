#if DEBUG
import Foundation

/// Development-only launch options, read from the environment so screens and
/// App Store screenshots can be reached without signing in or tapping:
/// `SIMCTL_CHILD_ISPOONFIT_GUEST=1 xcrun simctl launch <device> dev.ividi.ispoonfit`.
@MainActor
enum DebugLaunch {
    private static var environment: [String: String] { ProcessInfo.processInfo.environment }

    /// Skips Firebase and opens a local guest account.
    static var isGuest: Bool { environment["ISPOONFIT_GUEST"] == "1" }
    /// Finished sessions to seed into a guest account that has no program yet.
    static var demoSessions: Int? { environment["ISPOONFIT_DEMO"].flatMap(Int.init) }
    /// The tab to open on: today, program, exercises or settings.
    static var tab: String? { environment["ISPOONFIT_TAB"] }
    static var lowEnergy: Bool { environment["ISPOONFIT_LOWENERGY"] == "1" }
    static var seated: Bool { environment["ISPOONFIT_SEATED"] == "1" }

    /// Starts a program a few weeks back with `demoSessions` done on their
    /// own training days, all before today, so Today, Program and History
    /// look lived in and today's session is still to do.
    static func seed(_ viewModel: ProgramViewModel) {
        viewModel.lowEnergyToday = lowEnergy
        viewModel.seatedToday = seated
        guard let count = demoSessions, !viewModel.hasOnboarded, let context = viewModel.context else { return }
        let calendar = Calendar.current
        let thisMonday = ProgramState.nextMonday(after: Date()).addingTimeInterval(-7 * 86_400)
        let start = calendar.date(byAdding: .weekOfYear, value: -((count + ProgramData.daysPerWeek - 1) / ProgramData.daysPerWeek), to: thisMonday) ?? thisMonday
        viewModel.startProgram(startDate: start, reminderTime: nil, medicalClearance: true, healthProfile: .empty)
        for index in stride(from: 1, through: min(count, ProgramData.totalDays), by: 1) {
            let week = (index - 1) / ProgramData.daysPerWeek
            let weekday = (index - 1) % ProgramData.daysPerWeek
            let day = calendar.date(byAdding: .day, value: week * 7 + weekday, to: start) ?? start
            context.insert(CompletedSession(
                dayIndex: index,
                date: day.addingTimeInterval(9 * 3600),
                durationSeconds: 780 + index * 7,
                energy: 3 + index % 3,
                discomfort: 1 + index % 2
            ))
        }
        try? context.save()
        viewModel.refresh()
    }
}
#endif
