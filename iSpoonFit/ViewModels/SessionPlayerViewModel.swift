import Foundation

/// Drives one guided workout. The countdown is anchored to a `Date` rather
/// than counted in ticks, so locking the screen or switching apps never makes
/// the session drift.
@MainActor
@Observable
final class SessionPlayerViewModel {
    let day: ProgramDay

    private(set) var steps: [SessionStep]
    private(set) var index: Int = 0
    private(set) var remaining: Int
    private(set) var isPaused = false
    private(set) var isFinished = false
    private(set) var lowEnergy: Bool
    private(set) var showsSwitchSideBanner = false

    private var stepEndDate: Date?
    private var ticker: Task<Void, Never>?
    private var startedAt = Date()
    private var finishedAt: Date?
    private var pausedAt: Date?
    private var pausedTotal: TimeInterval = 0
    private var announcedSwitchSide = false

    init(day: ProgramDay, lowEnergy: Bool) {
        self.day = day
        self.lowEnergy = lowEnergy
        let built = SessionBuilder.steps(for: day, lowEnergy: lowEnergy)
        self.steps = built
        self.remaining = built.first?.seconds ?? 0
    }

    // MARK: - Derived state

    var currentStep: SessionStep {
        steps[min(index, steps.count - 1)]
    }

    /// The exercise the user should be looking at: on a rest or get-ready step
    /// that is the one coming up.
    var displayedRef: ExerciseRef { currentStep.ref }

    /// 1 → 0 across the current step, for the countdown ring.
    var stepProgress: Double {
        guard currentStep.seconds > 0 else { return 0 }
        return Double(remaining) / Double(currentStep.seconds)
    }

    var formattedRemaining: String {
        remaining >= 60
            ? String(format: "%d:%02d", remaining / 60, remaining % 60)
            : String(remaining)
    }

    /// One entry per work interval, used by the segmented bar at the bottom.
    var workStepIndices: [Int] {
        steps.indices.filter { steps[$0].isWork }
    }

    // MARK: - Lifecycle

    func start() {
        startedAt = Date()
        pausedTotal = 0
        beginStep()
        startTicker()
    }

    func stop() {
        ticker?.cancel()
        ticker = nil
        SessionAudio.shared.deactivate()
    }

    private func startTicker() {
        ticker?.cancel()
        ticker = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 100_000_000)
                guard let self else { return }
                self.tick()
            }
        }
    }

    /// Starts the current step. `anchor` is when it began: now for a manual
    /// skip, or the previous step's end when the clock rolls over, so time
    /// spent suspended is carried into the steps that should have run.
    private func beginStep(from anchor: Date = Date()) {
        let step = currentStep
        let end = anchor.addingTimeInterval(TimeInterval(step.seconds))
        stepEndDate = end
        remaining = max(0, Int(end.timeIntervalSinceNow.rounded(.up)))
        announcedSwitchSide = remaining <= (step.switchSideAtSecond ?? -1)
        showsSwitchSideBanner = false
        // Steps that already ran out while the app was suspended stay silent.
        if end.timeIntervalSinceNow > 0 {
            announceStepStart(step)
        }
    }

    private func announceStepStart(_ step: SessionStep) {
        switch step.kind {
        case .getReady:
            SessionAudio.shared.play(.countdownTick)
            SessionAudio.shared.speak(key: "session.getReady")
            Haptics.impact(.light)
        case .work:
            SessionAudio.shared.play(.workStart)
            SessionAudio.shared.speak(t(step.ref.catalogEntry.nameKey))
            Haptics.impact(.medium)
        case .rest:
            SessionAudio.shared.play(.restStart)
            SessionAudio.shared.speak(key: "session.rest")
            Haptics.impact(.light)
        }
    }

    // MARK: - Ticking

    private func tick() {
        guard !isPaused, !isFinished else { return }

        // After the app was suspended several steps may have run out at once.
        while !isFinished, let end = stepEndDate, end.timeIntervalSinceNow <= 0 {
            advance(from: end)
        }
        guard !isFinished, let end = stepEndDate else { return }

        let newRemaining = max(0, Int(end.timeIntervalSinceNow.rounded(.up)))
        if newRemaining != remaining {
            remaining = newRemaining
            handleCountdown(newRemaining)
            handleSwitchSide(newRemaining)
        }
    }

    private func handleCountdown(_ value: Int) {
        guard (1...3).contains(value) else { return }
        SessionAudio.shared.play(.countdownTick)
        Haptics.impact(.rigid)
        SessionAudio.shared.speak(Self.spelled(value))
    }

    private func handleSwitchSide(_ value: Int) {
        guard !announcedSwitchSide,
              let switchAt = currentStep.switchSideAtSecond,
              value <= switchAt else { return }
        announcedSwitchSide = true
        showsSwitchSideBanner = true
        SessionAudio.shared.play(.switchSide)
        SessionAudio.shared.speak(key: "session.switchSide")
        Haptics.warning()
        Task { [weak self] in
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            self?.showsSwitchSideBanner = false
        }
    }

    private static func spelled(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .spellOut
        formatter.locale = LocalizationManager.shared.current.locale
        return formatter.string(from: NSNumber(value: value)) ?? String(value)
    }

    // MARK: - Navigation

    private func advance(from anchor: Date = Date()) {
        if index + 1 < steps.count {
            index += 1
            beginStep(from: anchor)
        } else {
            finish(at: anchor)
        }
    }

    func skipForward() {
        Haptics.selection()
        advance()
    }

    func skipBackward() {
        Haptics.selection()
        guard index > 0 else {
            beginStep()
            return
        }
        index -= 1
        beginStep()
    }

    func togglePause() {
        isPaused.toggle()
        Haptics.selection()
        if isPaused {
            pausedAt = Date()
            SessionAudio.shared.stopSpeaking()
        } else if let pausedAt {
            pausedTotal += Date().timeIntervalSince(pausedAt)
            self.pausedAt = nil
            stepEndDate = Date().addingTimeInterval(TimeInterval(remaining))
        }
    }

    func pauseIfRunning() {
        guard !isPaused, !isFinished else { return }
        togglePause()
    }

    /// Rebuilds the session with the easier parameters. In the circuit it
    /// resumes from the start of the current round; in the warm-up and the
    /// stretches, which do not change, it stays on the same exercise.
    func switchToLowEnergy() {
        guard !lowEnergy else { return }
        let current = currentStep
        let offsetInBlock = steps[..<index].filter { $0.block == current.block }.count
        lowEnergy = true
        steps = SessionBuilder.steps(for: day, lowEnergy: true)

        let target: Int?
        if current.block == .workout {
            let maxRounds = steps.map(\.totalRounds).max() ?? 1
            let round = min(current.round, maxRounds)
            target = steps.firstIndex { $0.block == .workout && $0.round == round && $0.isWork }
        } else {
            let blockStart = steps.firstIndex { $0.block == current.block } ?? 0
            target = blockStart + offsetInBlock
        }
        index = min(target ?? 0, steps.count - 1)
        if isPaused { togglePause() }
        beginStep()
    }

    private func finish(at date: Date = Date()) {
        guard !isFinished else { return }
        isFinished = true
        finishedAt = date
        stepEndDate = nil
        ticker?.cancel()
        SessionAudio.shared.play(.finished)
        SessionAudio.shared.speak(key: "session.done")
        Haptics.success()
    }

    /// Wall-clock time spent in the session, ignoring time spent paused.
    /// Frozen once the session finishes, so time spent on the check-in
    /// screen is not counted.
    var completedDurationSeconds: Int {
        let end = finishedAt ?? Date()
        let paused = pausedTotal + (pausedAt.map { end.timeIntervalSince($0) } ?? 0)
        return max(0, Int(end.timeIntervalSince(startedAt) - paused))
    }
}
