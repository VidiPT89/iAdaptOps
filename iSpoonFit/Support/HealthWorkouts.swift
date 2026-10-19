import Foundation
import HealthKit

/// Saves each finished session to the Health app as a workout, when the user
/// turns it on in Settings. The app only writes: it never reads anything from
/// Health, and nothing written there leaves the device through the app.
@MainActor
enum HealthWorkouts {
    private static let store = HKHealthStore()
    private static let enabledKey = "healthWorkoutsEnabled"

    static var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    static var isEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: enabledKey) }
        set { UserDefaults.standard.set(newValue, forKey: enabledKey) }
    }

    /// Asks for permission to save workouts. Returns false when Health is
    /// unavailable or the user did not allow it, so the setting can switch
    /// itself back off.
    static func requestAccess() async -> Bool {
        guard isAvailable else { return false }
        let workout = HKObjectType.workoutType()
        do {
            try await store.requestAuthorization(toShare: [workout], read: [])
        } catch {
            return false
        }
        return store.authorizationStatus(for: workout) == .sharingAuthorized
    }

    /// Records one session that ended at `end` and lasted `durationSeconds`.
    /// Failures are silent: Health is a mirror, the app's own log is the
    /// record.
    static func save(end: Date, durationSeconds: Int) async {
        guard isEnabled, isAvailable, durationSeconds > 0,
              store.authorizationStatus(for: .workoutType()) == .sharingAuthorized else { return }
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .functionalStrengthTraining
        configuration.locationType = .indoor
        let builder = HKWorkoutBuilder(healthStore: store, configuration: configuration, device: .local())
        let start = end.addingTimeInterval(-TimeInterval(durationSeconds))
        do {
            try await builder.beginCollection(at: start)
            try await builder.endCollection(at: end)
            _ = try await builder.finishWorkout()
        } catch {
            builder.discardWorkout()
        }
    }
}
