import Foundation

/// Which plan an account follows. Everyone gets a plan generated from their
/// health questionnaire; the admin can instead assign a fixed plan, ahead of
/// time through an invite or later from the admin panel.
enum ProgramVariant: String, CaseIterable, Identifiable {
    /// Built by `CarePlanGenerator` from the person's own answers.
    case personalized
    /// Ana's "Desafio 28 dias", exactly as written: the same workouts, but
    /// week 1 closes with two one-minute stretches chosen for each day, and
    /// from day 5 the stretches are held 30 seconds per side.
    case anaChallenge

    var id: String { rawValue }
    var titleKey: String { "variant.\(rawValue)" }
    var descriptionKey: String { "variant.\(rawValue).desc" }

    /// Fixed plans ignore the questionnaire and skip it during onboarding.
    var isFixed: Bool { self != .personalized }

    /// Unknown or missing ids, and the old "standard" id, mean the
    /// personalized plan.
    init(id: String?) {
        self = id.flatMap(ProgramVariant.init(rawValue:)) ?? .personalized
    }

    func days(profile: HealthProfile?) -> [ProgramDay] {
        switch self {
        case .personalized: return CarePlanGenerator.days(for: profile ?? .empty)
        case .anaChallenge: return Self.anaChallengeDays
        }
    }


    // MARK: - Ana's challenge

    private static let anaChallengeDays: [ProgramDay] = ProgramData.days.map { day in
        var copy = day
        copy.cooldown = anaCooldown(forDay: day.index)
        return copy
    }

    private static func step(_ id: ExerciseID, _ seconds: Int) -> TimedStep {
        TimedStep(ref: ExerciseRef(id), seconds: seconds)
    }

    /// The stretches exactly as the plan lists them.
    static func anaCooldown(forDay index: Int) -> [TimedStep] {
        switch index {
        case 1: return [step(.childsPose, 60), step(.hamstringStretch, 60)]
        case 2: return [step(.figureFour, 60), step(.quadStretch, 60)]
        case 3: return [step(.childsPose, 60), step(.hipFlexorStretch, 60)]
        case 4: return [step(.sideStretch, 60), step(.hamstringStretch, 60)]
        // "Termina com 2 minutos de alongamentos completos."
        case ProgramData.totalDays: return ProgramData.cooldown
        // "Posição da criança 30 s; figura 4, quadríceps e posterior da
        // coxa 30 s por lado."
        default:
            return [
                step(.childsPose, 30),
                step(.figureFour, 60),
                step(.quadStretch, 60),
                step(.hamstringStretch, 60)
            ]
        }
    }
}
