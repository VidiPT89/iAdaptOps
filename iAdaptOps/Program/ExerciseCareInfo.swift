import Foundation

/// How an exercise is done and what it asks of the body, which is what the
/// plan generator uses to decide whether it suits a person.
struct ExerciseCareInfo {
    enum Position {
        case seated, standing, standingSupported, floorSupine, floorSide, allFours, kneeling
    }

    enum Focus {
        case mobility, breathing, lowerStrength, upperStrength, core, balance, stretch
    }

    /// Demands that some conditions or limitations rule out.
    enum Load {
        /// Weight through bent knees.
        case knee
        /// Weight through the hands and wrists.
        case wrist
        /// Arms working at or above shoulder height.
        case shoulder
        /// A held effort that raises blood pressure.
        case isometric
        /// Rounding or side-bending the spine.
        case spinalFlexion
        /// Twisting the spine.
        case twist
        /// Pushing a joint to the end of its range.
        case deepRange
        /// Standing on one leg or stepping.
        case balance
    }

    let position: Position
    let focus: Set<Focus>
    /// 1 is the easiest; a plan never uses a level above its own tier.
    let level: Int
    let loads: Set<Load>

    static func info(_ id: ExerciseID) -> ExerciseCareInfo {
        table[id]!
    }

    private static let table: [ExerciseID: ExerciseCareInfo] = [
        // Warm-up
        .marchInPlace: .init(position: .standing, focus: [.mobility], level: 1, loads: []),
        .gentleSquat: .init(position: .standing, focus: [.lowerStrength], level: 1, loads: [.knee]),
        .hipCircles: .init(position: .standing, focus: [.mobility], level: 1, loads: []),
        .armSwings: .init(position: .standing, focus: [.mobility, .upperStrength], level: 1, loads: [.shoulder]),
        // Legs and glutes
        .sumoSquat: .init(position: .standing, focus: [.lowerStrength], level: 2, loads: [.knee, .deepRange]),
        .squat: .init(position: .standing, focus: [.lowerStrength], level: 2, loads: [.knee]),
        .shortLunge: .init(position: .standing, focus: [.lowerStrength], level: 3, loads: [.knee, .balance]),
        .alternatingLunge: .init(position: .standing, focus: [.lowerStrength], level: 3, loads: [.knee, .balance, .deepRange]),
        .wallSit: .init(position: .standing, focus: [.lowerStrength], level: 2, loads: [.knee, .isometric]),
        .calfRaise: .init(position: .standingSupported, focus: [.lowerStrength, .balance], level: 1, loads: []),
        .sideLegRaise: .init(position: .floorSide, focus: [.lowerStrength], level: 2, loads: []),
        // Core on the floor
        .gluteBridge: .init(position: .floorSupine, focus: [.lowerStrength, .core], level: 1, loads: []),
        .marchingBridge: .init(position: .floorSupine, focus: [.core], level: 2, loads: []),
        .birdDog: .init(position: .allFours, focus: [.core, .balance], level: 2, loads: [.wrist, .knee]),
        .deadBug: .init(position: .floorSupine, focus: [.core], level: 2, loads: []),
        .heelTaps: .init(position: .floorSupine, focus: [.core], level: 1, loads: []),
        .pelvicTilt: .init(position: .floorSupine, focus: [.core, .breathing], level: 1, loads: []),
        // Stretches
        .childsPose: .init(position: .kneeling, focus: [.stretch], level: 1, loads: [.knee, .spinalFlexion]),
        .figureFour: .init(position: .floorSupine, focus: [.stretch], level: 1, loads: []),
        .quadStretch: .init(position: .standingSupported, focus: [.stretch], level: 1, loads: [.knee, .balance]),
        .hamstringStretch: .init(position: .floorSupine, focus: [.stretch], level: 1, loads: []),
        .hipFlexorStretch: .init(position: .kneeling, focus: [.stretch], level: 1, loads: [.knee]),
        .sideStretch: .init(position: .standing, focus: [.stretch, .mobility], level: 1, loads: [.spinalFlexion, .shoulder]),
        // Care
        .seatedMarch: .init(position: .seated, focus: [.mobility, .lowerStrength, .core], level: 1, loads: []),
        .seatedKneeExtension: .init(position: .seated, focus: [.lowerStrength], level: 1, loads: []),
        .sitToStand: .init(position: .standingSupported, focus: [.lowerStrength], level: 2, loads: [.knee]),
        .wallPushUp: .init(position: .standing, focus: [.upperStrength], level: 1, loads: [.wrist, .shoulder]),
        .shoulderRolls: .init(position: .seated, focus: [.mobility, .upperStrength], level: 1, loads: []),
        .diaphragmaticBreathing: .init(position: .seated, focus: [.breathing, .core], level: 1, loads: []),
        .seatedCatCow: .init(position: .seated, focus: [.mobility, .stretch], level: 1, loads: [.spinalFlexion]),
        .seatedRotation: .init(position: .seated, focus: [.mobility, .stretch], level: 1, loads: [.twist]),
        .supportedBalance: .init(position: .standingSupported, focus: [.balance], level: 2, loads: [.balance]),
        .standingHipAbduction: .init(position: .standingSupported, focus: [.lowerStrength, .balance], level: 1, loads: [])
    ]
}
