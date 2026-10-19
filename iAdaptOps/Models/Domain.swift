import Foundation

enum BlockKind: String, Codable, CaseIterable {
    case warmup, workout, cooldown

    var titleKey: String {
        switch self {
        case .warmup: return "block.warmup"
        case .workout: return "block.workout"
        case .cooldown: return "block.cooldown"
        }
    }

    var icon: String {
        switch self {
        case .warmup: return "sunrise.fill"
        case .workout: return "flame.fill"
        case .cooldown: return "leaf.fill"
        }
    }
}

/// Small adjustments layered on top of a catalog exercise for a given day.
enum Modifier: String, Codable, CaseIterable {
    case deeper, hold2s, hold1s, slow, pulse, weighted

    var labelKey: String { "modifier.\(rawValue)" }
    var descriptionKey: String { "modifier.\(rawValue).desc" }

    /// How long one full repetition takes, used to slow down or speed up the
    /// demo animation so it matches the instruction.
    var cycleDuration: Double? {
        switch self {
        case .slow: return 6
        case .pulse: return 0.6
        case .hold2s: return 3.2
        case .hold1s: return 2.6
        default: return nil
        }
    }
}

enum ExerciseCategory: String, Codable, CaseIterable, Identifiable {
    case warmup, mobility, legsGlutes, core, upperBody, balance, stretch

    var id: String { rawValue }
    var titleKey: String { "category.\(rawValue)" }

    var icon: String {
        switch self {
        case .warmup: return "sunrise.fill"
        case .mobility: return "wind"
        case .legsGlutes: return "figure.strengthtraining.functional"
        case .upperBody: return "figure.arms.open"
        case .balance: return "figure.stand"
        case .core: return "figure.core.training"
        case .stretch: return "figure.flexibility"
        }
    }
}

/// Stable identifier for every exercise in the catalog. Also the prefix used
/// to look up its coaching text (`cue.<rawValue>.steps` and friends).
enum ExerciseID: String, Codable, CaseIterable, Identifiable {
    case marchInPlace, gentleSquat, hipCircles, armSwings
    case sumoSquat, squat, shortLunge, alternatingLunge, wallSit, calfRaise, sideLegRaise
    case gluteBridge, marchingBridge, birdDog, deadBug, heelTaps, pelvicTilt
    case childsPose, figureFour, quadStretch, hamstringStretch, hipFlexorStretch, sideStretch
    // Care exercises: seated, chair-supported or against a wall.
    case seatedMarch, seatedKneeExtension, sitToStand, wallPushUp, shoulderRolls
    case diaphragmaticBreathing, seatedCatCow, seatedRotation, supportedBalance, standingHipAbduction

    var id: String { rawValue }

    var stepsKey: String { "cue.\(rawValue).steps" }
    var breathingKey: String { "cue.\(rawValue).breathing" }
    var mistakeKey: String { "cue.\(rawValue).mistake" }
    var easierKey: String { "cue.\(rawValue).easier" }
    var cautionKey: String { "cue.\(rawValue).caution" }
}

struct Exercise: Identifiable, Hashable {
    let id: ExerciseID
    let nameKey: String
    let category: ExerciseCategory
    let motion: ExerciseMotionKind
    let isUnilateral: Bool
    let muscleKeys: [String]
}

/// An exercise as it appears on a specific day, with that day's modifiers.
struct ExerciseRef: Codable, Hashable, Identifiable {
    let exercise: ExerciseID
    let modifiers: [Modifier]

    var id: String { ([exercise.rawValue] + modifiers.map(\.rawValue)).joined(separator: "-") }

    init(_ exercise: ExerciseID, modifiers: [Modifier] = []) {
        self.exercise = exercise
        self.modifiers = modifiers
    }

    var catalogEntry: Exercise { ExerciseCatalog.exercise(exercise) }

    /// "Agachamento sumo · com garrafas"
    @MainActor
    var displayName: String {
        let base = t(catalogEntry.nameKey)
        guard !modifiers.isEmpty else { return base }
        return base + " · " + modifiers.map { t($0.labelKey) }.joined(separator: ", ")
    }

    @MainActor
    var modifierLabel: String? {
        guard !modifiers.isEmpty else { return nil }
        return modifiers.map { t($0.labelKey) }.joined(separator: " · ")
    }

    /// Removing the load is what "low-energy day" does to each exercise,
    /// before the timing changes are applied.
    var softened: ExerciseRef {
        ExerciseRef(exercise, modifiers: modifiers.filter { $0 != .weighted })
    }

    var animationCycleDuration: Double {
        modifiers.compactMap(\.cycleDuration).min() ?? 2.0
    }
}

struct WeekParams: Hashable {
    let work: Int
    let rest: Int
    let rounds: Int
    let phaseKey: String

    var phaseDescriptionKey: String { phaseKey + ".desc" }
}

/// One exercise of the warm-up or the closing stretches and how long it
/// lasts. Unilateral moves split the time between both sides.
struct TimedStep: Hashable {
    let ref: ExerciseRef
    let seconds: Int
}

struct ProgramDay: Identifiable, Hashable {
    let index: Int
    let titleKey: String
    var exercises: [ExerciseRef]
    /// The opening moves. Fixed plans use the shared routine; a generated
    /// plan picks moves that suit the person.
    var warmup: [TimedStep] = ProgramData.warmupSteps
    /// The closing stretches, shared or chosen per day in the same way.
    var cooldown: [TimedStep] = ProgramData.cooldown
    /// Work, rest and rounds when the plan sets its own; otherwise the week's.
    var paramsOverride: WeekParams? = nil

    var id: Int { index }

    /// Weeks 1...7, four training days each.
    var week: Int { (index - 1) / 4 + 1 }

    /// 0 = Monday ... 3 = Thursday.
    var weekday: Int { (index - 1) % 4 }

    var weekdayKey: String {
        ["weekday.mon", "weekday.tue", "weekday.wed", "weekday.thu"][weekday]
    }

    var params: WeekParams { paramsOverride ?? ProgramData.params(forWeek: week) }

    var isFinalDay: Bool { index == ProgramData.totalDays }

    /// The same session done from a chair: every warm-up move and exercise
    /// that is not already seated becomes a seated one with the same focus,
    /// without repeating a move within a block. The closing stretches stay,
    /// since they are already done at rest.
    var seatedVersion: ProgramDay {
        var copy = self
        var usedInWarmup: [ExerciseID] = []
        copy.warmup = warmup.map { step in
            TimedStep(ref: Self.seated(step.ref, avoiding: &usedInWarmup), seconds: step.seconds)
        }
        var usedInWorkout: [ExerciseID] = []
        copy.exercises = exercises.map { Self.seated($0, avoiding: &usedInWorkout) }
        return copy
    }

    /// Whether the seated version changes anything, so the option is only
    /// offered when it does.
    var hasSeatedVersion: Bool { seatedVersion != self }

    /// Seated moves with no joint loads, so they suit every plan.
    private static let seatedMoves: [ExerciseID] = [
        .seatedMarch, .seatedKneeExtension, .shoulderRolls, .diaphragmaticBreathing
    ]

    private static func seated(_ ref: ExerciseRef, avoiding used: inout [ExerciseID]) -> ExerciseRef {
        let info = ExerciseCareInfo.info(ref.exercise)
        if info.position == .seated, !used.contains(ref.exercise) {
            used.append(ref.exercise)
            return ref
        }
        let preferred: [ExerciseID]
        if info.focus.contains(.lowerStrength) {
            preferred = [.seatedKneeExtension, .seatedMarch]
        } else if info.focus.contains(.upperStrength) || info.focus.contains(.mobility) {
            preferred = [.shoulderRolls, .seatedMarch]
        } else if info.focus.contains(.breathing) {
            preferred = [.diaphragmaticBreathing]
        } else {
            preferred = [.seatedMarch, .diaphragmaticBreathing]
        }
        let pick = (preferred + seatedMoves).first { !used.contains($0) } ?? .seatedMarch
        used.append(pick)
        return ExerciseRef(pick)
    }

    /// Distinct focus areas across the day's exercises, for the chips on the
    /// Today card.
    var focusKeys: [String] {
        var keys: [String] = []
        for ref in exercises {
            let entry = ref.catalogEntry
            let key: String
            switch entry.category {
            case .core: key = "focus.core"
            case .legsGlutes: key = entry.muscleKeys.contains("muscle.glutes") ? "focus.glutes" : "focus.thighs"
            default: continue
            }
            if !keys.contains(key) { keys.append(key) }
        }
        return keys
    }
}

enum StepKind: String, Hashable {
    case getReady, work, rest
}

/// One timed slice of a guided session. `ref` on a rest or get-ready step is
/// the exercise that comes next, so the player can preview it.
struct SessionStep: Identifiable, Hashable {
    let id: Int
    let kind: StepKind
    let block: BlockKind
    let ref: ExerciseRef
    let round: Int
    let totalRounds: Int
    let seconds: Int

    var isRest: Bool { kind == .rest }
    var isWork: Bool { kind == .work }

    /// Unilateral work is split down the middle with a "switch sides" cue.
    var switchSideAtSecond: Int? {
        guard kind == .work, ref.catalogEntry.isUnilateral else { return nil }
        return seconds / 2
    }
}
