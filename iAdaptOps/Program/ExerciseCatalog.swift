import Foundation

/// Every exercise the program can use. The catalog is static data: names and
/// coaching text live in the translation table, keyed off each `ExerciseID`.
enum ExerciseCatalog {
    static let all: [Exercise] = [
        // MARK: Warm-up
        Exercise(
            id: .marchInPlace, nameKey: "exercise.marchInPlace", category: .warmup,
            motion: .marchInPlace, isUnilateral: false,
            muscleKeys: ["muscle.hipFlexors", "muscle.core"]
        ),
        Exercise(
            id: .gentleSquat, nameKey: "exercise.gentleSquat", category: .warmup,
            motion: .gentleSquat, isUnilateral: false,
            muscleKeys: ["muscle.quads", "muscle.glutes"]
        ),
        Exercise(
            id: .hipCircles, nameKey: "exercise.hipCircles", category: .warmup,
            motion: .hipCircle, isUnilateral: false,
            muscleKeys: ["muscle.hipFlexors", "muscle.core"]
        ),
        Exercise(
            id: .armSwings, nameKey: "exercise.armSwings", category: .warmup,
            motion: .armSwing, isUnilateral: false,
            muscleKeys: ["muscle.shoulders", "muscle.chest"]
        ),

        // MARK: Legs and glutes
        Exercise(
            id: .sumoSquat, nameKey: "exercise.sumoSquat", category: .legsGlutes,
            motion: .sumoSquat, isUnilateral: false,
            muscleKeys: ["muscle.adductors", "muscle.glutes", "muscle.quads"]
        ),
        Exercise(
            id: .squat, nameKey: "exercise.squat", category: .legsGlutes,
            motion: .squat, isUnilateral: false,
            muscleKeys: ["muscle.quads", "muscle.glutes"]
        ),
        Exercise(
            id: .shortLunge, nameKey: "exercise.shortLunge", category: .legsGlutes,
            motion: .shortLunge, isUnilateral: false,
            muscleKeys: ["muscle.quads", "muscle.glutes"]
        ),
        Exercise(
            id: .alternatingLunge, nameKey: "exercise.alternatingLunge", category: .legsGlutes,
            motion: .lunge, isUnilateral: false,
            muscleKeys: ["muscle.quads", "muscle.glutes"]
        ),
        Exercise(
            id: .wallSit, nameKey: "exercise.wallSit", category: .legsGlutes,
            motion: .wallSit, isUnilateral: false,
            muscleKeys: ["muscle.quads", "muscle.glutes"]
        ),
        Exercise(
            id: .calfRaise, nameKey: "exercise.calfRaise", category: .legsGlutes,
            motion: .calfRaise, isUnilateral: false,
            muscleKeys: ["muscle.calves"]
        ),
        Exercise(
            id: .sideLegRaise, nameKey: "exercise.sideLegRaise", category: .legsGlutes,
            motion: .sideLegRaise, isUnilateral: true,
            muscleKeys: ["muscle.gluteMedius", "muscle.abductors"]
        ),

        // MARK: Core and glutes on the floor
        Exercise(
            id: .gluteBridge, nameKey: "exercise.gluteBridge", category: .core,
            motion: .bridge, isUnilateral: false,
            muscleKeys: ["muscle.glutes", "muscle.hamstrings", "muscle.deepCore"]
        ),
        Exercise(
            id: .marchingBridge, nameKey: "exercise.marchingBridge", category: .core,
            motion: .marchingBridge, isUnilateral: false,
            muscleKeys: ["muscle.glutes", "muscle.deepCore", "muscle.hamstrings"]
        ),
        Exercise(
            id: .birdDog, nameKey: "exercise.birdDog", category: .core,
            motion: .birdDog, isUnilateral: false,
            muscleKeys: ["muscle.deepCore", "muscle.glutes", "muscle.lowerBack"]
        ),
        Exercise(
            id: .deadBug, nameKey: "exercise.deadBug", category: .core,
            motion: .deadBug, isUnilateral: false,
            muscleKeys: ["muscle.deepCore", "muscle.transverseAbdominis"]
        ),
        Exercise(
            id: .heelTaps, nameKey: "exercise.heelTaps", category: .core,
            motion: .heelTap, isUnilateral: false,
            muscleKeys: ["muscle.deepCore", "muscle.transverseAbdominis"]
        ),
        Exercise(
            id: .pelvicTilt, nameKey: "exercise.pelvicTilt", category: .core,
            motion: .pelvicTilt, isUnilateral: false,
            muscleKeys: ["muscle.transverseAbdominis", "muscle.pelvicFloor"]
        ),

        // MARK: Stretches
        Exercise(
            id: .childsPose, nameKey: "stretch.childsPose", category: .stretch,
            motion: .childsPose, isUnilateral: false,
            muscleKeys: ["muscle.lowerBack", "muscle.spine"]
        ),
        Exercise(
            id: .figureFour, nameKey: "stretch.figureFour", category: .stretch,
            motion: .figureFour, isUnilateral: true,
            muscleKeys: ["muscle.glutes", "muscle.gluteMedius"]
        ),
        Exercise(
            id: .quadStretch, nameKey: "stretch.quad", category: .stretch,
            motion: .quadStretch, isUnilateral: true,
            muscleKeys: ["muscle.quads"]
        ),
        Exercise(
            id: .hamstringStretch, nameKey: "stretch.hamstring", category: .stretch,
            motion: .hamstringStretch, isUnilateral: true,
            muscleKeys: ["muscle.hamstrings"]
        ),
        Exercise(
            id: .hipFlexorStretch, nameKey: "stretch.hipFlexor", category: .stretch,
            motion: .hipFlexorStretch, isUnilateral: true,
            muscleKeys: ["muscle.hipFlexors", "muscle.quads"]
        ),
        Exercise(
            id: .sideStretch, nameKey: "stretch.side", category: .stretch,
            motion: .sideStretch, isUnilateral: true,
            muscleKeys: ["muscle.obliques", "muscle.lowerBack"]
        ),

        // MARK: Care: seated, chair-supported or against a wall
        Exercise(
            id: .seatedMarch, nameKey: "exercise.seatedMarch", category: .mobility,
            motion: .seatedMarch, isUnilateral: false,
            muscleKeys: ["muscle.hipFlexors", "muscle.core"]
        ),
        Exercise(
            id: .seatedKneeExtension, nameKey: "exercise.seatedKneeExtension", category: .legsGlutes,
            motion: .seatedKneeExtension, isUnilateral: false,
            muscleKeys: ["muscle.quads"]
        ),
        Exercise(
            id: .sitToStand, nameKey: "exercise.sitToStand", category: .legsGlutes,
            motion: .sitToStand, isUnilateral: false,
            muscleKeys: ["muscle.quads", "muscle.glutes"]
        ),
        Exercise(
            id: .wallPushUp, nameKey: "exercise.wallPushUp", category: .upperBody,
            motion: .wallPushUp, isUnilateral: false,
            muscleKeys: ["muscle.chest", "muscle.shoulders"]
        ),
        Exercise(
            id: .shoulderRolls, nameKey: "exercise.shoulderRolls", category: .mobility,
            motion: .shoulderRoll, isUnilateral: false,
            muscleKeys: ["muscle.shoulders", "muscle.neck"]
        ),
        Exercise(
            id: .diaphragmaticBreathing, nameKey: "exercise.diaphragmaticBreathing", category: .mobility,
            motion: .breathing, isUnilateral: false,
            muscleKeys: ["muscle.diaphragm", "muscle.deepCore"]
        ),
        Exercise(
            id: .seatedCatCow, nameKey: "exercise.seatedCatCow", category: .mobility,
            motion: .seatedCatCow, isUnilateral: false,
            muscleKeys: ["muscle.spine", "muscle.lowerBack"]
        ),
        Exercise(
            id: .seatedRotation, nameKey: "exercise.seatedRotation", category: .mobility,
            motion: .seatedRotation, isUnilateral: false,
            muscleKeys: ["muscle.spine", "muscle.obliques"]
        ),
        Exercise(
            id: .supportedBalance, nameKey: "exercise.supportedBalance", category: .balance,
            motion: .supportedBalance, isUnilateral: true,
            muscleKeys: ["muscle.calves", "muscle.gluteMedius"]
        ),
        Exercise(
            id: .standingHipAbduction, nameKey: "exercise.standingHipAbduction", category: .balance,
            motion: .standingHipAbduction, isUnilateral: true,
            muscleKeys: ["muscle.gluteMedius", "muscle.abductors"]
        )
    ]

    private static let byID: [ExerciseID: Exercise] = Dictionary(
        uniqueKeysWithValues: all.map { ($0.id, $0) }
    )

    static func exercise(_ id: ExerciseID) -> Exercise {
        // Every ID has an entry; the fallback only keeps the API non-optional.
        byID[id] ?? all[0]
    }

}

extension ExerciseRef {
    /// The animation to play, after the day's modifiers are taken into account.
    /// A pulsed squat gets its own short-travel motion rather than the full one.
    var motion: ExerciseMotionKind {
        let base = catalogEntry.motion
        if modifiers.contains(.pulse), base == .squat { return .pulseSquat }
        return base
    }
}
