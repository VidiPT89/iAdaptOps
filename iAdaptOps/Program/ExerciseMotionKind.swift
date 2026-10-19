import Foundation

/// One stick-figure motion archetype per exercise. Every drawing in the app
/// goes through this enum, so there are no bundled videos or images and the
/// whole catalog stays offline and weightless.
enum ExerciseMotionKind: String, CaseIterable {
    // Standing
    case marchInPlace
    case gentleSquat
    case squat
    case sumoSquat
    case pulseSquat
    case hipCircle
    case armSwing
    case shortLunge
    case lunge
    case wallSit
    case calfRaise
    case quadStretch
    case hipFlexorStretch
    case sideStretch

    // Seated or supported
    case seatedMarch
    case seatedKneeExtension
    case sitToStand
    case wallPushUp
    case shoulderRoll
    case breathing
    case seatedCatCow
    case seatedRotation
    case supportedBalance
    case standingHipAbduction

    // On the floor
    case sideLegRaise
    case bridge
    case marchingBridge
    case birdDog
    case deadBug
    case heelTap
    case pelvicTilt
    case childsPose
    case figureFour
    case hamstringStretch

    /// Floor exercises are drawn lying along the x-axis, which also raises the
    /// ground line so the figure still sits on it.
    var isHorizontal: Bool {
        switch self {
        case .marchInPlace, .gentleSquat, .squat, .sumoSquat, .pulseSquat, .hipCircle,
             .armSwing, .shortLunge, .lunge, .wallSit, .calfRaise, .quadStretch,
             .hipFlexorStretch, .sideStretch, .seatedMarch, .seatedKneeExtension, .sitToStand,
             .wallPushUp, .shoulderRoll, .breathing, .seatedCatCow, .seatedRotation,
             .supportedBalance, .standingHipAbduction:
            return false
        default:
            return true
        }
    }

    /// Floor work is drawn on a mat; standing work is not.
    var usesMat: Bool { isHorizontal }

    var prop: ExerciseProp? {
        switch self {
        case .wallSit, .wallPushUp: return .wall
        case .calfRaise, .shortLunge, .lunge, .quadStretch, .supportedBalance, .standingHipAbduction: return .chair
        case .seatedMarch, .seatedKneeExtension, .sitToStand, .shoulderRoll, .breathing, .seatedCatCow: return .seat
        case .seatedRotation: return .seatFront
        case .hamstringStretch: return .towel
        default: return nil
        }
    }

    /// Isometric holds get a slow halo that expands and contracts, standing in
    /// for the breath the instructions ask for.
    var hasBreathingGlow: Bool {
        switch self {
        case .wallSit, .childsPose, .breathing: return true
        default: return false
        }
    }

    var defaultCycleDuration: Double {
        switch self {
        case .pulseSquat: return 0.6
        case .wallSit, .childsPose: return 4.0
        case .hipCircle: return 3.0
        case .hipFlexorStretch, .sideStretch, .seatedCatCow, .seatedRotation: return 4.0
        case .breathing: return 6.0
        case .sitToStand, .wallPushUp, .shoulderRoll: return 3.0
        case .seatedMarch: return 1.6
        case .marchInPlace: return 1.2
        default: return 2.0
        }
    }
}

/// Simple scene furniture drawn behind or beside the figure.
enum ExerciseProp {
    case chair
    case wall
    case towel
    /// A chair seen from the side, with the figure sitting on it.
    case seat
    /// A chair seen from the front, with the figure sitting on it.
    case seatFront
}
