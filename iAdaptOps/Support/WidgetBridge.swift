import Foundation
import WidgetKit

/// Keeps the home-screen widget in step with the signed-in account.
@MainActor
enum WidgetBridge {
    static func update(from viewModel: ProgramViewModel) {
        guard let state = viewModel.state else {
            clear()
            return
        }
        let next = viewModel.nextDay.map { day in
            WidgetSnapshot.NextWorkout(
                dayIndex: day.index,
                week: day.week,
                title: t(day.titleKey),
                minutes: SessionBuilder.estimatedMinutes(for: day)
            )
        }
        let snapshot = WidgetSnapshot(
            language: LocalizationManager.shared.current.rawValue,
            completed: viewModel.completedCount,
            total: ProgramData.totalDays,
            startDate: state.startDate,
            lastWorkoutDate: viewModel.sessions.first?.date,
            next: next
        )
        if WidgetSnapshot.save(snapshot) {
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    /// After signing out, so the next person never sees someone else's plan.
    static func clear() {
        if WidgetSnapshot.save(nil) {
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
}
