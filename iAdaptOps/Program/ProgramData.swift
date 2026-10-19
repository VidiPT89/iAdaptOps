import Foundation

private func ref(_ id: ExerciseID, _ modifiers: Modifier...) -> ExerciseRef {
    ExerciseRef(id, modifiers: modifiers)
}

private func programDay(_ index: Int, _ titleKey: String, _ exercises: ExerciseRef...) -> ProgramDay {
    ProgramDay(index: index, titleKey: titleKey, exercises: exercises)
}

/// The fixed 28-day program: seven weeks of four training days, Monday to
/// Thursday, with Friday to Sunday off.
enum ProgramData {
    static let totalDays = 28
    static let totalWeeks = 7
    static let daysPerWeek = 4

    static let weekParams: [Int: WeekParams] = [
        1: WeekParams(work: 40, rest: 20, rounds: 3, phaseKey: "phase.foundation"),
        2: WeekParams(work: 40, rest: 20, rounds: 3, phaseKey: "phase.foundation"),
        3: WeekParams(work: 45, rest: 15, rounds: 3, phaseKey: "phase.firming"),
        4: WeekParams(work: 45, rest: 15, rounds: 3, phaseKey: "phase.firming"),
        5: WeekParams(work: 45, rest: 15, rounds: 4, phaseKey: "phase.endurance"),
        6: WeekParams(work: 45, rest: 15, rounds: 4, phaseKey: "phase.endurance"),
        7: WeekParams(work: 50, rest: 10, rounds: 4, phaseKey: "phase.consolidation")
    ]

    static func params(forWeek week: Int) -> WeekParams {
        weekParams[min(max(week, 1), totalWeeks)] ?? weekParams[1]!
    }

    /// Identical in every session: four moves, 45 seconds each, no rest.
    static let warmup: [ExerciseRef] = [
        ref(.marchInPlace), ref(.gentleSquat), ref(.hipCircles), ref(.armSwings)
    ]
    static let warmupSeconds = 45
    static let warmupSteps: [TimedStep] = warmup.map { TimedStep(ref: $0, seconds: warmupSeconds) }

    /// Identical in every session: two minutes of stretching to finish.
    static let cooldown: [TimedStep] = [
        TimedStep(ref: ref(.childsPose), seconds: 30),
        TimedStep(ref: ref(.figureFour), seconds: 30),
        TimedStep(ref: ref(.quadStretch), seconds: 30),
        TimedStep(ref: ref(.hamstringStretch), seconds: 30)
    ]

    /// Seconds spent on the "get ready" step before the first warm-up move.
    static let getReadySeconds = 5

    static let days: [ProgramDay] = [
        programDay(1, "day.activateCoreLegs", ref(.sumoSquat), ref(.gluteBridge), ref(.birdDog), ref(.sideLegRaise)),
        programDay(2, "day.thighsGlutes", ref(.wallSit), ref(.gluteBridge), ref(.sideLegRaise), ref(.calfRaise)),
        programDay(3, "day.postpartumCore", ref(.deadBug), ref(.heelTaps), ref(.birdDog), ref(.pelvicTilt)),
        programDay(4, "day.fullBody", ref(.sumoSquat), ref(.shortLunge), ref(.gluteBridge), ref(.birdDog)),

        programDay(5, "day.controlRange", ref(.sumoSquat, .deeper), ref(.gluteBridge, .hold2s), ref(.birdDog, .slow), ref(.sideLegRaise)),
        programDay(6, "day.thighsGlutes", ref(.wallSit), ref(.calfRaise), ref(.gluteBridge), ref(.heelTaps)),
        programDay(7, "day.postpartumCore", ref(.deadBug), ref(.pelvicTilt), ref(.birdDog), ref(.gluteBridge)),
        programDay(8, "day.fullBody", ref(.sumoSquat), ref(.shortLunge), ref(.sideLegRaise), ref(.gluteBridge)),

        programDay(9, "day.pulsesActivation", ref(.squat, .pulse), ref(.gluteBridge, .pulse), ref(.birdDog), ref(.heelTaps)),
        programDay(10, "day.thighsGlutes", ref(.wallSit), ref(.sideLegRaise), ref(.calfRaise), ref(.gluteBridge)),
        programDay(11, "day.postpartumCore", ref(.deadBug), ref(.pelvicTilt), ref(.birdDog), ref(.gluteBridge)),
        programDay(12, "day.fullBody", ref(.sumoSquat), ref(.shortLunge), ref(.marchingBridge), ref(.heelTaps)),

        programDay(13, "day.firstLoad", ref(.squat, .pulse, .weighted), ref(.gluteBridge, .pulse), ref(.birdDog), ref(.heelTaps)),
        programDay(14, "day.thighsGlutes", ref(.wallSit), ref(.gluteBridge, .pulse), ref(.calfRaise), ref(.heelTaps)),
        programDay(15, "day.postpartumCore", ref(.deadBug), ref(.birdDog), ref(.pelvicTilt), ref(.gluteBridge)),
        programDay(16, "day.fullBody", ref(.sumoSquat), ref(.shortLunge), ref(.sideLegRaise), ref(.gluteBridge)),

        programDay(17, "day.loadedStrength", ref(.sumoSquat, .weighted), ref(.marchingBridge), ref(.birdDog), ref(.heelTaps)),
        programDay(18, "day.thighsGlutes", ref(.wallSit), ref(.sideLegRaise, .hold1s), ref(.calfRaise), ref(.gluteBridge, .pulse)),
        programDay(19, "day.postpartumCore", ref(.deadBug), ref(.pelvicTilt), ref(.birdDog), ref(.gluteBridge)),
        programDay(20, "day.fullBody", ref(.sumoSquat), ref(.shortLunge), ref(.marchingBridge), ref(.heelTaps)),

        programDay(21, "day.pulsesActivation", ref(.squat, .pulse), ref(.gluteBridge, .pulse), ref(.birdDog), ref(.sideLegRaise)),
        programDay(22, "day.thighsGlutes", ref(.wallSit), ref(.calfRaise), ref(.heelTaps), ref(.gluteBridge)),
        programDay(23, "day.postpartumCore", ref(.deadBug), ref(.pelvicTilt), ref(.birdDog), ref(.marchingBridge)),
        programDay(24, "day.fullBody", ref(.sumoSquat, .weighted), ref(.shortLunge), ref(.sideLegRaise), ref(.heelTaps)),

        programDay(25, "day.loadedStrength", ref(.sumoSquat, .weighted), ref(.marchingBridge), ref(.birdDog), ref(.heelTaps)),
        programDay(26, "day.thighsGlutes", ref(.wallSit), ref(.sideLegRaise), ref(.calfRaise), ref(.gluteBridge, .pulse)),
        programDay(27, "day.postpartumCore", ref(.deadBug), ref(.pelvicTilt), ref(.birdDog), ref(.gluteBridge)),
        programDay(28, "day.finalChallenge", ref(.sumoSquat, .weighted), ref(.alternatingLunge), ref(.marchingBridge), ref(.heelTaps))
    ]


}
