import Foundation

/// Turns a program day into the flat list of timed steps the player walks
/// through. Pure and deterministic, so the whole session can be reasoned about
/// (and tested) without any UI.
enum SessionBuilder {
    /// Timing for one day, after the low-energy adjustment: one round fewer
    /// (never below one), ten seconds off the work (never below 15) and ten
    /// onto the rest. Care plans already start at two rounds of 20 seconds, so
    /// the floor has to sit below that for the mode to change anything.
    /// How much slower the demonstrations move on a low-energy day, so the
    /// figure models an unhurried pace.
    static let lowEnergyPace = 1.5

    static func params(for day: ProgramDay, lowEnergy: Bool) -> WeekParams {
        let base = day.params
        guard lowEnergy else { return base }
        return WeekParams(
            work: max(15, base.work - 10),
            rest: base.rest + 10,
            rounds: max(1, base.rounds - 1),
            phaseKey: base.phaseKey
        )
    }

    static func steps(for day: ProgramDay, lowEnergy: Bool = false) -> [SessionStep] {
        let params = params(for: day, lowEnergy: lowEnergy)
        let exercises = lowEnergy ? day.exercises.map(\.softened) : day.exercises
        var steps: [SessionStep] = []

        func append(_ kind: StepKind, _ block: BlockKind, _ ref: ExerciseRef, _ seconds: Int, round: Int = 1, totalRounds: Int = 1) {
            steps.append(
                SessionStep(
                    id: steps.count,
                    kind: kind,
                    block: block,
                    ref: ref,
                    round: round,
                    totalRounds: totalRounds,
                    seconds: seconds
                )
            )
        }

        // Get ready, previewing the first warm-up move.
        append(.getReady, .warmup, day.warmup.first?.ref ?? ProgramData.warmup[0], ProgramData.getReadySeconds)

        // Warm-up runs straight through, no rest between moves.
        for entry in day.warmup {
            append(.work, .warmup, entry.ref, entry.seconds)
        }

        // Circuit: every work interval is followed by a rest, except the very
        // last one, which runs straight into the stretching block.
        for round in 1...params.rounds {
            for (index, exercise) in exercises.enumerated() {
                append(.work, .workout, exercise, params.work, round: round, totalRounds: params.rounds)

                let isLastOfRound = index == exercises.count - 1
                let isLastRound = round == params.rounds
                guard !(isLastOfRound && isLastRound) else { continue }

                let next = isLastOfRound ? exercises[0] : exercises[index + 1]
                append(.rest, .workout, next, params.rest, round: round, totalRounds: params.rounds)
            }
        }

        // Stretching, also continuous.
        for entry in day.cooldown {
            append(.work, .cooldown, entry.ref, entry.seconds)
        }

        return steps
    }

    static func totalSeconds(for day: ProgramDay, lowEnergy: Bool = false) -> Int {
        steps(for: day, lowEnergy: lowEnergy).reduce(0) { $0 + $1.seconds }
    }

    /// Rounded to whole minutes for the duration shown on cards.
    static func estimatedMinutes(for day: ProgramDay, lowEnergy: Bool = false) -> Int {
        Int((Double(totalSeconds(for: day, lowEnergy: lowEnergy)) / 60).rounded())
    }
}
