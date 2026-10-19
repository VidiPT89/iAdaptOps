import Foundation
import SwiftData

/// Owns the persisted program state and the completed-session log, and derives
/// everything the screens need from them: which day is next, how far along the
/// program is, and which achievements have been earned.
@MainActor
@Observable
final class ProgramViewModel {
    private(set) var state: ProgramState?
    private(set) var sessions: [CompletedSession] = []

    private(set) var context: ModelContext?
    /// Nil for a local-only session (tests, or a debug build without Firebase).
    private(set) var sync: CloudSyncing?
    /// Name and email sent up with the profile, so the admin can tell
    /// accounts apart.
    private(set) var profile: (name: String?, email: String?) = (nil, nil)
    /// A program assigned in the cloud before this account finished
    /// onboarding; used when the local program is created.
    var assignedProgramID: String?
    /// Questionnaire answers found in the cloud before this device finished
    /// onboarding, applied when the local program is created.
    var pendingHealthJSON: String?
    @ObservationIgnored private var planCache: (key: String, days: [ProgramDay])?
    private let calendar = Calendar.current

    /// Reset every calendar day, so "low-energy" never silently carries over.
    var lowEnergyToday: Bool {
        didSet { Self.persist(lowEnergyToday, key: Self.lowEnergyKey) }
    }

    /// The seated version of today's session, offered on low-energy days and
    /// reset every calendar day in the same way.
    var seatedToday: Bool {
        didSet { Self.persist(seatedToday, key: Self.seatedKey) }
    }

    init() {
        lowEnergyToday = Self.storedToday(key: Self.lowEnergyKey)
        seatedToday = Self.storedToday(key: Self.seatedKey)
    }

    private static let lowEnergyKey = "lowEnergyToday"
    private static let seatedKey = "seatedToday"

    private static func storedToday(key: String) -> Bool {
        let storedDay = UserDefaults.standard.object(forKey: key + "Date") as? Date
        let isToday = storedDay.map { Calendar.current.isDateInToday($0) } ?? false
        return isToday && UserDefaults.standard.bool(forKey: key)
    }

    private static func persist(_ value: Bool, key: String) {
        UserDefaults.standard.set(value, forKey: key)
        UserDefaults.standard.set(Date(), forKey: key + "Date")
    }

    /// The day as it will be played today: seated when that was chosen.
    func playable(_ day: ProgramDay) -> ProgramDay {
        lowEnergyToday && seatedToday ? day.seatedVersion : day
    }

    // MARK: - Loading

    func load(context: ModelContext, sync: CloudSyncing? = nil, name: String? = nil, email: String? = nil) {
        self.context = context
        self.sync = sync
        profile = (name, email)
        refresh()
    }

    // MARK: - Program variant

    var variant: ProgramVariant { ProgramVariant(id: state?.programID ?? assignedProgramID) }

    private var healthJSON: String? { state?.healthProfileJSON ?? pendingHealthJSON }

    var healthProfile: HealthProfile? { healthJSON.flatMap { try? HealthProfile(json: $0) } }

    /// A personalized plan that has never had its questionnaire answered
    /// (accounts created before it existed) should ask for it.
    var needsQuestionnaire: Bool { !variant.isFixed && healthProfile == nil }

    /// Every day of this account's plan. Generated plans are cheap but read
    /// often, so they are kept until the answers or the plan change.
    var planDays: [ProgramDay] {
        let key = variant.rawValue + "|" + (healthJSON ?? "")
        if let cache = planCache, cache.key == key { return cache.days }
        let days = variant.days(profile: healthProfile)
        planCache = (key, days)
        return days
    }

    func day(at index: Int) -> ProgramDay? {
        let days = planDays
        guard index >= 1, index <= days.count else { return nil }
        return days[index - 1]
    }

    func days(inWeek week: Int) -> [ProgramDay] { planDays.filter { $0.week == week } }

    /// Saves new questionnaire answers; the plan regenerates from them.
    /// Completed days keep counting, since progress is stored by day number.
    func updateHealthProfile(_ profile: HealthProfile) {
        guard let state, let context else { return }
        state.healthProfileJSON = profile.sanitized.encoded
        state.healthUpdatedAt = .now
        try? context.save()
        refresh()
        pushHealth()
    }

    func refresh() {
        guard let context else { return }
        state = (try? context.fetch(FetchDescriptor<ProgramState>()))?.first
        // Sorted here rather than with a SortDescriptor, whose key path is not
        // Sendable and would not compile in the Swift 6 language mode.
        let all = (try? context.fetch(FetchDescriptor<CompletedSession>())) ?? []
        sessions = all.sorted { $0.date > $1.date }
        WidgetBridge.update(from: self)
    }

    var hasOnboarded: Bool { state != nil }

    func startProgram(
        startDate: Date,
        reminderTime: Date?,
        medicalClearance: Bool,
        healthProfile: HealthProfile? = nil
    ) {
        guard let context else { return }
        let newState = ProgramState(
            startDate: startDate,
            reminderTime: reminderTime,
            reminderEnabled: reminderTime != nil,
            medicalClearance: medicalClearance
        )
        newState.programID = variant.rawValue
        if let healthProfile {
            newState.healthProfileJSON = healthProfile.sanitized.encoded
            newState.healthUpdatedAt = .now
        } else if let pendingHealthJSON {
            newState.healthProfileJSON = pendingHealthJSON
            newState.healthUpdatedAt = .now
        }
        context.insert(newState)
        try? context.save()
        refresh()
        pushState()
        pushHealth()
        if let reminderTime {
            Task { await updateReminder(enabled: true, time: reminderTime) }
        }
    }

    /// Saves the reminder preference and schedules or cancels the
    /// notifications. Returns false when iOS refused permission, in which case
    /// the preference is stored as off.
    @discardableResult
    func updateReminder(enabled: Bool, time: Date) async -> Bool {
        let granted = enabled ? await ReminderManager.schedule(at: time) : true
        if !enabled { ReminderManager.cancelAll() }
        guard let state, let context else { return granted }
        state.reminderEnabled = enabled && granted
        state.reminderTime = time
        state.updatedAt = .now
        try? context.save()
        pushState()
        return granted
    }

    /// Reminders are scheduled on the device, so they are set up again after
    /// signing in on a new phone, and after a language change, since their
    /// text is fixed when scheduled.
    func rescheduleReminderIfNeeded() {
        guard let state, state.reminderEnabled, let time = state.reminderTime else { return }
        Task { await ReminderManager.schedule(at: time) }
    }

    func updateStartDate(_ date: Date) {
        guard let state, let context else { return }
        state.startDate = calendar.startOfDay(for: date)
        state.updatedAt = .now
        try? context.save()
        refresh()
        pushState()
    }

    // MARK: - Progress

    var completedDayIndices: Set<Int> { Set(sessions.map(\.dayIndex)) }

    var completedCount: Int { completedDayIndices.count }

    var progress: Double { Double(completedCount) / Double(ProgramData.totalDays) }

    var isProgramComplete: Bool { completedCount >= ProgramData.totalDays }

    /// The first day still to be done. Missing a day never blocks the program:
    /// the next available workout is simply the first unfinished one.
    var nextDayIndex: Int? {
        (1...ProgramData.totalDays).first { !completedDayIndices.contains($0) }
    }

    var nextDay: ProgramDay? { nextDayIndex.flatMap(day(at:)) }

    /// A day can be started once every earlier day is done.
    func isUnlocked(_ day: ProgramDay) -> Bool {
        guard day.index > 1 else { return true }
        return completedDayIndices.contains(day.index - 1) || completedDayIndices.contains(day.index)
    }

    func isCompleted(_ day: ProgramDay) -> Bool { completedDayIndices.contains(day.index) }

    /// Done, but only ever in low-energy mode: the calendar marks it with a leaf.
    func isCompletedOnlyOnLowEnergy(_ day: ProgramDay) -> Bool {
        let runs = sessions.filter { $0.dayIndex == day.index }
        return !runs.isEmpty && runs.allSatisfy(\.lowEnergy)
    }

    func completedDays(inWeek week: Int) -> Int {
        days(inWeek: week).filter { isCompleted($0) }.count
    }

    func isWeekComplete(_ week: Int) -> Bool {
        completedDays(inWeek: week) == ProgramData.daysPerWeek
    }

    var weeksCompleted: Int {
        (1...ProgramData.totalWeeks).filter { isWeekComplete($0) }.count
    }

    var totalMinutes: Int {
        Int((Double(sessions.reduce(0) { $0 + $1.durationSeconds }) / 60).rounded())
    }

    // MARK: - Calendar

    /// Whole days left before the chosen start date; zero once it has come.
    var daysUntilStart: Int {
        guard let start = state?.startDate else { return 0 }
        let today = calendar.startOfDay(for: Date())
        let days = calendar.dateComponents([.day], from: today, to: calendar.startOfDay(for: start)).day ?? 0
        return max(0, days)
    }

    /// One workout a day is the plan; after that Today suggests resting.
    var hasTrainedToday: Bool {
        sessions.contains { calendar.isDateInToday($0.date) }
    }

    /// Friday, Saturday and Sunday are rest days.
    var isRestDayToday: Bool {
        let weekday = calendar.component(.weekday, from: Date())
        return weekday == 6 || weekday == 7 || weekday == 1
    }

    /// Days until the next Monday to Thursday slot, for the rest-day card.
    var daysUntilNextTrainingDay: Int {
        let weekday = calendar.component(.weekday, from: Date())
        switch weekday {
        case 6: return 3   // Friday
        case 7: return 2   // Saturday
        case 1: return 1   // Sunday
        default: return 0
        }
    }

    // MARK: - Mutations

    func complete(
        day: ProgramDay,
        durationSeconds: Int,
        lowEnergy: Bool,
        energy: Int? = nil,
        discomfort: Int? = nil,
        note: String? = nil
    ) {
        guard let context else { return }
        let session = CompletedSession(
            dayIndex: day.index,
            durationSeconds: durationSeconds,
            lowEnergy: lowEnergy,
            energy: energy,
            discomfort: discomfort,
            note: note?.isEmpty == true ? nil : note
        )
        context.insert(session)
        try? context.save()
        lowEnergyToday = false
        seatedToday = false
        refresh()
        push(session)
        let end = session.date
        Task { await HealthWorkouts.save(end: end, durationSeconds: durationSeconds) }
    }

    func delete(_ session: CompletedSession) {
        guard let context else { return }
        let id = session.uuid
        context.delete(session)
        try? context.save()
        refresh()
        removeRemoteSessions([id])
    }

    func restartProgram() {
        guard let context else { return }
        let ids = sessions.map(\.uuid)
        for session in sessions {
            context.delete(session)
        }
        state?.startDate = ProgramState.nextMonday()
        state?.updatedAt = .now
        try? context.save()
        lowEnergyToday = false
        seatedToday = false
        refresh()
        removeRemoteSessions(ids)
        pushState()
    }

    /// Clears what this device keeps outside the account's store, so the
    /// next person to sign in on it starts clean.
    static func clearDeviceState() {
        for key in [lowEnergyKey, seatedKey] {
            UserDefaults.standard.removeObject(forKey: key)
            UserDefaults.standard.removeObject(forKey: key + "Date")
        }
        ReminderManager.cancelAll()
        // The Health app belongs to the phone's owner, not to whoever signs in next.
        HealthWorkouts.isEnabled = false
        WidgetBridge.clear()
    }

    // MARK: - Achievements

    /// "First load" only makes sense in plans that use water bottles.
    var achievements: [Achievement] {
        let usesLoad = planDays.contains { day in day.exercises.contains { $0.modifiers.contains(.weighted) } }
        return Achievement.allCases.filter { $0 != .firstLoad || usesLoad }
    }

    func isUnlocked(_ achievement: Achievement) -> Bool {
        achievement.isUnlocked(in: self)
    }
}

enum Achievement: String, CaseIterable, Identifiable {
    case firstWorkout, firstWeek, halfway, firstLoad, finalChallenge

    var id: String { rawValue }
    var titleKey: String { "achievement.\(rawValue)" }

    var icon: String {
        switch self {
        case .firstWorkout: return "sparkles"
        case .firstWeek: return "calendar.badge.checkmark"
        case .halfway: return "flag.checkered"
        case .firstLoad: return "dumbbell.fill"
        case .finalChallenge: return "trophy.fill"
        }
    }

    @MainActor
    func isUnlocked(in viewModel: ProgramViewModel) -> Bool {
        let done = viewModel.completedDayIndices
        switch self {
        case .firstWorkout: return !done.isEmpty
        case .firstWeek: return viewModel.isWeekComplete(1)
        case .halfway: return done.contains(14)
        case .firstLoad: return done.contains(13)
        case .finalChallenge: return done.contains(28)
        }
    }
}
