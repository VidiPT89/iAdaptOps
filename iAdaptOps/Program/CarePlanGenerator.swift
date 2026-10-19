import Foundation

/// Builds a 28-session care plan from the start-up questionnaire. Pure and
/// deterministic: the same answers always give the same plan, so it is
/// regenerated on every device instead of being stored.
///
/// The rules are deliberately conservative. They choose a gentle pace from
/// age, energy, activity and conditions, then remove every exercise whose
/// position or load does not suit the person. Anything left out is replaced
/// by a seated alternative, never by something harder.
enum CarePlanGenerator {
    struct Rules: Equatable {
        /// 1 very gentle, 2 gentle, 3 moderate.
        let tier: Int
        let excludedPositions: Set<ExerciseCareInfo.Position>
        let excludedLoads: Set<ExerciseCareInfo.Load>
        /// Balance work only with both hands on the chair.
        let supportedBalanceOnly: Bool

        func allows(_ id: ExerciseID) -> Bool {
            let info = ExerciseCareInfo.info(id)
            if excludedPositions.contains(info.position) { return false }
            if !info.loads.isDisjoint(with: excludedLoads) { return false }
            if supportedBalanceOnly, info.loads.contains(.balance), info.position != .standingSupported {
                return false
            }
            return true
        }
    }

    // MARK: - Reading the answers

    static func rules(for profile: HealthProfile) -> Rules {
        let answers = profile.sanitized
        let conditions = answers.conditions
        let limits = answers.limitations
        var positions: Set<ExerciseCareInfo.Position> = []
        var loads: Set<ExerciseCareInfo.Load> = []

        let floorIsHard = limits.contains(.cannotGetToFloor)
            || conditions.contains(.parkinsons)
            || (answers.bodyMassIndex ?? 0) >= 40
        if floorIsHard {
            positions.formUnion([.floorSupine, .floorSide, .allFours, .kneeling])
        }
        if limits.contains(.kneePain) || conditions.contains(.osteoarthritis) {
            loads.insert(.knee)
            positions.insert(.kneeling)
        }
        if limits.contains(.wristHandPain) || conditions.contains(.inflammatoryArthritis) {
            loads.insert(.wrist)
            positions.insert(.allFours)
        }
        if limits.contains(.shoulderPain) {
            loads.insert(.shoulder)
        }
        if limits.contains(.lowBackPain) || conditions.contains(.chronicBackPain) || conditions.contains(.hypermobility) {
            loads.insert(.deepRange)
        }
        if conditions.contains(.osteoporosis) {
            loads.formUnion([.spinalFlexion, .twist, .deepRange])
        }
        if conditions.contains(.heartCondition) || conditions.contains(.respiratory) {
            loads.insert(.isometric)
        }
        // Standing for long, or standing up and down repeatedly, can bring
        // on fatigue crashes and dizziness: keep these plans seated or lying.
        if conditions.contains(.chronicFatigue) || conditions.contains(.pots) {
            positions.formUnion([.standing, .standingSupported])
        } else if limits.contains(.cannotStandLong) {
            positions.insert(.standing)
        }
        let balanceRisk = limits.contains(.dizziness)
            || conditions.contains(.multipleSclerosis)
            || conditions.contains(.parkinsons)
            || (answers.age ?? 0) >= 75

        return Rules(
            tier: tier(for: answers),
            excludedPositions: positions,
            excludedLoads: loads,
            supportedBalanceOnly: balanceRisk
        )
    }

    static func tier(for profile: HealthProfile) -> Int {
        let conditions = profile.conditions
        var tier: Int
        switch profile.activity {
        case .none: tier = 1
        case .light: tier = 2
        case .regular: tier = 3
        }
        if profile.energy <= 2 { tier -= 1 }
        if !conditions.isDisjoint(with: [.fibromyalgia, .lupus, .multipleSclerosis, .inflammatoryArthritis]) {
            tier -= 1
        }
        if !conditions.isDisjoint(with: [.heartCondition, .respiratory, .cancer, .parkinsons]) {
            tier = min(tier, 2)
        }
        if let age = profile.age {
            if age >= 75 { tier = min(tier, 1) } else if age >= 65 { tier = min(tier, 2) }
        }
        // Energy-limiting illnesses always start at the gentlest pace.
        if !conditions.isDisjoint(with: [.chronicFatigue, .longCovid, .pots]) {
            tier = 1
        }
        return min(max(tier, 1), 3)
    }

    // MARK: - Timing

    /// Work, rest and rounds for each tier across the four phases.
    private static let pacing: [Int: [(work: Int, rest: Int, rounds: Int)]] = [
        1: [(20, 40, 2), (25, 35, 2), (30, 30, 2), (30, 30, 3)],
        2: [(30, 30, 2), (30, 30, 3), (35, 25, 3), (40, 20, 3)],
        3: [(35, 25, 3), (40, 20, 3), (40, 20, 3), (45, 15, 3)]
    ]

    private static let phaseKeys = ["phase.care.start", "phase.care.build", "phase.care.strength", "phase.care.consolidate"]

    private static func phase(forWeek week: Int) -> Int {
        switch week {
        case 1...2: return 0
        case 3...4: return 1
        case 5...6: return 2
        default: return 3
        }
    }

    static func params(forWeek week: Int, tier: Int) -> WeekParams {
        let phase = phase(forWeek: week)
        let step = pacing[tier]![phase]
        return WeekParams(work: step.work, rest: step.rest, rounds: step.rounds, phaseKey: phaseKeys[phase])
    }

    // MARK: - Building the plan

    private typealias Focus = ExerciseCareInfo.Focus

    /// One theme per training day of the week, Monday to Thursday.
    private static let themes: [(titleKey: String, slots: [Focus])] = [
        ("day.care.mobility", [.mobility, .breathing, .upperStrength, .core]),
        ("day.care.strength", [.lowerStrength, .lowerStrength, .upperStrength, .core]),
        ("day.care.core", [.core, .core, .breathing, .mobility]),
        ("day.care.balance", [.lowerStrength, .balance, .upperStrength, .core])
    ]

    /// Always allowed: seated, no loads. The last resort for any slot.
    private static let seatedFallbacks: [ExerciseID] = [
        .seatedMarch, .seatedKneeExtension, .shoulderRolls, .diaphragmaticBreathing
    ]

    static func days(for profile: HealthProfile) -> [ProgramDay] {
        let rules = rules(for: profile)
        return (1...ProgramData.totalDays).map { index in
            day(index, rules: rules)
        }
    }

    private static func day(_ index: Int, rules: Rules) -> ProgramDay {
        let week = (index - 1) / ProgramData.daysPerWeek + 1
        let weekday = (index - 1) % ProgramData.daysPerWeek
        let theme = themes[weekday]
        let params = params(forWeek: week, tier: rules.tier)
        let targetLevel = min(phase(forWeek: week) == 0 ? 1 : phase(forWeek: week), rules.tier)

        let warmup = warmup(rules: rules)
        let warmupIDs = warmup.map(\.ref.exercise)
        var chosen: [ExerciseID] = []
        for (slot, focus) in theme.slots.enumerated() {
            let pick = bestExercise(
                for: focus, rules: rules, targetLevel: targetLevel,
                excluding: chosen, avoiding: warmupIDs,
                rotation: week * 3 + slot + weekday * 7
            )
            chosen.append(pick)
        }

        var day = ProgramDay(
            index: index,
            titleKey: index == ProgramData.totalDays ? "day.care.final" : theme.titleKey,
            exercises: chosen.map { ExerciseRef($0) }
        )
        day.warmup = warmup
        day.cooldown = cooldown(rules: rules, dayIndex: index, avoiding: chosen)
        day.paramsOverride = params
        return day
    }

    private static func bestExercise(
        for focus: Focus,
        rules: Rules,
        targetLevel: Int,
        excluding used: [ExerciseID],
        avoiding warmup: [ExerciseID],
        rotation: Int
    ) -> ExerciseID {
        let all = ExerciseID.allCases
        func candidates(strict: Bool) -> [(offset: Int, element: ExerciseID)] {
            all.enumerated().filter { _, id in
                let info = ExerciseCareInfo.info(id)
                // Warm-up moves and the day's own warm-up are a last resort,
                // so the main block brings something new.
                if strict, ExerciseCatalog.exercise(id).category == .warmup || warmup.contains(id) {
                    return false
                }
                return info.focus.contains(focus)
                    && !info.focus.contains(.stretch)
                    && info.level <= rules.tier
                    && !used.contains(id)
                    && rules.allows(id)
            }
        }
        let pool = candidates(strict: true).isEmpty ? candidates(strict: false) : candidates(strict: true)
        let best = pool.min { lhs, rhs in
            let lDistance = abs(ExerciseCareInfo.info(lhs.element).level - targetLevel)
            let rDistance = abs(ExerciseCareInfo.info(rhs.element).level - targetLevel)
            if lDistance != rDistance { return lDistance < rDistance }
            return (lhs.offset + rotation) % all.count < (rhs.offset + rotation) % all.count
        }
        if let best { return best.element }
        return seatedFallbacks.first { !used.contains($0) } ?? .diaphragmaticBreathing
    }

    /// Four gentle moves; standing ones when standing suits the person.
    private static func warmup(rules: Rules) -> [TimedStep] {
        let slots: [[ExerciseID]] = [
            [.marchInPlace, .seatedMarch],
            [.hipCircles, .seatedCatCow, .seatedKneeExtension],
            [.armSwings, .shoulderRolls, .diaphragmaticBreathing],
            [.seatedRotation, .seatedKneeExtension, .diaphragmaticBreathing]
        ]
        let seconds = rules.tier == 1 ? 30 : 40
        var picked: [ExerciseID] = []
        for options in slots {
            let pick = options.first { rules.allows($0) && !picked.contains($0) }
                ?? seatedFallbacks.first { !picked.contains($0) }
                ?? .diaphragmaticBreathing
            picked.append(pick)
        }
        return picked.map { TimedStep(ref: ExerciseRef($0), seconds: seconds) }
    }

    /// Three stretches that suit the person, varied from day to day and not
    /// repeating the main block, then slow breathing to finish.
    private static func cooldown(rules: Rules, dayIndex: Int, avoiding main: [ExerciseID]) -> [TimedStep] {
        let suitable: [ExerciseID] = [
            .childsPose, .figureFour, .hamstringStretch, .hipFlexorStretch,
            .sideStretch, .quadStretch, .seatedCatCow, .seatedRotation, .shoulderRolls
        ].filter(rules.allows)
        let fresh = suitable.filter { !main.contains($0) }
        let stretches = fresh.count >= 3 ? fresh : suitable
        var picked: [ExerciseID] = []
        if !stretches.isEmpty {
            for offset in 0..<min(3, stretches.count) {
                picked.append(stretches[(dayIndex + offset) % stretches.count])
            }
        }
        var steps = picked.map { TimedStep(ref: ExerciseRef($0), seconds: 30) }
        steps.append(TimedStep(ref: ExerciseRef(.diaphragmaticBreathing), seconds: 45))
        return steps
    }
}
