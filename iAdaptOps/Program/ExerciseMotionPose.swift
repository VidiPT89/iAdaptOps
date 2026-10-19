import CoreGraphics
import Foundation

/// A stick figure at one instant, in normalized coordinates where (0,0) is the
/// top-leading corner of the drawing area and (1,1) the bottom-trailing one.
/// Every value stays inside 0...1 so the same pose renders at any size.
struct StickPose: Equatable {
    var head: CGPoint
    var neck: CGPoint
    var hip: CGPoint
    var elbowL: CGPoint
    var handL: CGPoint
    var elbowR: CGPoint
    var handR: CGPoint
    var kneeL: CGPoint
    var footL: CGPoint
    var kneeR: CGPoint
    var footR: CGPoint

    /// Floor exercises lay the body along the x-axis and sit on a mat.
    var horizontal: Bool = false

    /// 0...1 halo amount for isometric holds, driving the breathing glow.
    var breathing: Double = 0

    /// Direction hints drawn as small arrows next to the figure.
    var arrows: [MotionArrow] = []

    var joints: [CGPoint] {
        [head, neck, hip, elbowL, handL, elbowR, handR, kneeL, footL, kneeR, footR]
    }

    /// Mirrors the figure across the vertical centre line, which is how the
    /// alternating exercises show that the working side has changed.
    func mirrored() -> StickPose {
        func flip(_ p: CGPoint) -> CGPoint { CGPoint(x: 1 - p.x, y: p.y) }
        var copy = self
        copy.head = flip(head); copy.neck = flip(neck); copy.hip = flip(hip)
        copy.elbowL = flip(elbowR); copy.handL = flip(handR)
        copy.elbowR = flip(elbowL); copy.handR = flip(handL)
        copy.kneeL = flip(kneeR); copy.footL = flip(footR)
        copy.kneeR = flip(kneeL); copy.footR = flip(footL)
        copy.arrows = arrows.map { MotionArrow(from: flip($0.from), to: flip($0.to)) }
        return copy
    }
}

struct MotionArrow: Equatable {
    var from: CGPoint
    var to: CGPoint
}

// MARK: - Shared math

func motionWave(_ phase: Double) -> Double { sin(phase * 2 * .pi) }

func motionWave01(_ phase: Double) -> Double { (motionWave(phase) + 1) / 2 }

/// Splits a cycle in two, returning how far into the current half we are as a
/// smooth 0 → 1 → 0 ramp plus which half it is. Alternating exercises use it
/// to extend one side, come back, then mirror and repeat.
func motionHalfCycle(_ phase: Double) -> (ping: Double, isFirstHalf: Bool) {
    let doubled = phase * 2
    let local = doubled - doubled.rounded(.down)
    return (sin(local * .pi), doubled.rounded(.down).truncatingRemainder(dividingBy: 2) == 0)
}

func motionLerp(_ a: CGPoint, _ b: CGPoint, _ t: Double) -> CGPoint {
    CGPoint(x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t)
}

// MARK: - Pose source

enum ExerciseMotionPose {
    /// The single entry point used by the renderer. `phase` loops over 0...1.
    static func pose(for kind: ExerciseMotionKind, phase: Double) -> StickPose {
        let p = phase - phase.rounded(.down)
        switch kind {
        case .marchInPlace: return marchInPlace(p)
        case .gentleSquat: return squat(p, depth: 0.5)
        case .squat: return squat(p, depth: 1)
        case .sumoSquat: return sumoSquat(p)
        case .pulseSquat: return pulseSquat(p)
        case .hipCircle: return hipCircle(p)
        case .armSwing: return armSwing(p)
        case .shortLunge: return lunge(p, stepLength: 0.7)
        case .lunge: return lunge(p, stepLength: 1)
        case .wallSit: return wallSit(p)
        case .calfRaise: return calfRaise(p)
        case .quadStretch: return quadStretch(p)
        case .hipFlexorStretch: return hipFlexorStretch(p)
        case .sideStretch: return sideStretch(p)
        case .seatedMarch: return seatedMarch(p)
        case .seatedKneeExtension: return seatedKneeExtension(p)
        case .sitToStand: return sitToStand(p)
        case .wallPushUp: return wallPushUp(p)
        case .shoulderRoll: return shoulderRoll(p)
        case .breathing: return breathing(p)
        case .seatedCatCow: return seatedCatCow(p)
        case .seatedRotation: return seatedRotation(p)
        case .supportedBalance: return supportedBalance(p)
        case .standingHipAbduction: return standingHipAbduction(p)
        case .sideLegRaise: return sideLegRaise(p)
        case .bridge: return bridge(p)
        case .marchingBridge: return marchingBridge(p)
        case .birdDog: return birdDog(p)
        case .deadBug: return deadBug(p)
        case .heelTap: return heelTap(p)
        case .pelvicTilt: return pelvicTilt(p)
        case .childsPose: return childsPose(p)
        case .figureFour: return figureFour(p)
        case .hamstringStretch: return hamstringStretch(p)
        }
    }

    /// The single most readable frame, shown instead of the loop when the
    /// system has Reduce Motion turned on.
    static func keyPose(for kind: ExerciseMotionKind) -> StickPose {
        pose(for: kind, phase: 0.25)
    }

    // MARK: Standing

    static func marchInPlace(_ p: Double) -> StickPose {
        let s = motionWave(p)
        let liftL = max(0, s)
        let liftR = max(0, -s)
        return StickPose(
            head: CGPoint(x: 0.50, y: 0.15),
            neck: CGPoint(x: 0.50, y: 0.25),
            hip: CGPoint(x: 0.50, y: 0.52),
            elbowL: CGPoint(x: 0.415, y: 0.375 - 0.05 * liftR),
            handL: CGPoint(x: 0.40 + 0.02 * liftR, y: 0.50 - 0.14 * liftR),
            elbowR: CGPoint(x: 0.585, y: 0.375 - 0.05 * liftL),
            handR: CGPoint(x: 0.60 - 0.02 * liftL, y: 0.50 - 0.14 * liftL),
            kneeL: CGPoint(x: 0.455 + 0.02 * liftL, y: 0.72 - 0.17 * liftL),
            footL: CGPoint(x: 0.46 + 0.03 * liftL, y: 0.92 - 0.26 * liftL),
            kneeR: CGPoint(x: 0.545 - 0.02 * liftR, y: 0.72 - 0.17 * liftR),
            footR: CGPoint(x: 0.54 - 0.03 * liftR, y: 0.92 - 0.26 * liftR),
            arrows: [MotionArrow(from: CGPoint(x: 0.30, y: 0.80), to: CGPoint(x: 0.30, y: 0.64))]
        )
    }

    static func squat(_ p: Double, depth: Double) -> StickPose {
        squatShape(drop: 0.13 * depth * motionWave01(p), spread: motionWave01(p), stance: 0.05)
    }

    static func sumoSquat(_ p: Double) -> StickPose {
        let s = motionWave01(p)
        var pose = squatShape(drop: 0.15 * s, spread: s, stance: 0.16, kneeFlare: 0.05)
        // Hands meet in front of the chest, which is also where the bottles go.
        pose.elbowL = CGPoint(x: 0.42, y: 0.40 + 0.06 * s)
        pose.handL = CGPoint(x: 0.470, y: 0.47 + 0.09 * s)
        pose.elbowR = CGPoint(x: 0.58, y: 0.40 + 0.06 * s)
        pose.handR = CGPoint(x: 0.530, y: 0.47 + 0.09 * s)
        return pose
    }

    static func pulseSquat(_ p: Double) -> StickPose {
        squatShape(drop: 0.14 + 0.022 * motionWave(p), spread: 1, stance: 0.06)
    }

    /// Shared squat geometry: the hip drops, the head follows, and each knee
    /// sits halfway between hip and foot so the legs always look connected.
    private static func squatShape(
        drop: Double,
        spread: Double,
        stance: Double,
        kneeFlare: Double = 0.035
    ) -> StickPose {
        let hip = CGPoint(x: 0.50, y: 0.52 + drop)
        let footL = CGPoint(x: 0.45 - stance, y: 0.92)
        let footR = CGPoint(x: 0.55 + stance, y: 0.92)
        let kneeL = CGPoint(x: footL.x - kneeFlare * spread, y: (hip.y + footL.y) / 2)
        let kneeR = CGPoint(x: footR.x + kneeFlare * spread, y: (hip.y + footR.y) / 2)
        return StickPose(
            head: CGPoint(x: 0.50, y: 0.15 + drop),
            neck: CGPoint(x: 0.50, y: 0.25 + drop),
            hip: hip,
            elbowL: CGPoint(x: 0.40, y: 0.38 + drop * 0.6),
            handL: CGPoint(x: 0.385, y: 0.50 - 0.10 * spread + drop * 0.6),
            elbowR: CGPoint(x: 0.60, y: 0.38 + drop * 0.6),
            handR: CGPoint(x: 0.615, y: 0.50 - 0.10 * spread + drop * 0.6),
            kneeL: kneeL,
            footL: footL,
            kneeR: kneeR,
            footR: footR,
            arrows: [MotionArrow(from: CGPoint(x: 0.26, y: 0.50), to: CGPoint(x: 0.26, y: 0.66))]
        )
    }

    static func hipCircle(_ p: Double) -> StickPose {
        let theta = p * 2 * .pi
        let dx = cos(theta), dy = sin(theta)
        let hip = CGPoint(x: 0.50 + 0.055 * dx, y: 0.52 + 0.028 * dy)
        return StickPose(
            head: CGPoint(x: 0.50 - 0.028 * dx, y: 0.15 - 0.014 * dy),
            neck: CGPoint(x: 0.50 - 0.012 * dx, y: 0.25 - 0.008 * dy),
            hip: hip,
            elbowL: CGPoint(x: 0.385, y: 0.43),
            handL: CGPoint(x: hip.x - 0.05, y: hip.y - 0.025),
            elbowR: CGPoint(x: 0.615, y: 0.43),
            handR: CGPoint(x: hip.x + 0.05, y: hip.y - 0.025),
            kneeL: CGPoint(x: 0.455 + 0.018 * dx, y: 0.72),
            footL: CGPoint(x: 0.45, y: 0.92),
            kneeR: CGPoint(x: 0.545 + 0.018 * dx, y: 0.72),
            footR: CGPoint(x: 0.55, y: 0.92),
            arrows: [MotionArrow(from: CGPoint(x: 0.26, y: 0.54), to: CGPoint(x: 0.30, y: 0.48))]
        )
    }

    static func armSwing(_ p: Double) -> StickPose {
        let open = motionWave01(p)
        let reach = 0.22 * open - 0.11 * (1 - open)
        let bob = 0.006 * motionWave(p * 2)
        return StickPose(
            head: CGPoint(x: 0.50, y: 0.15 + bob),
            neck: CGPoint(x: 0.50, y: 0.25 + bob),
            hip: CGPoint(x: 0.50, y: 0.52 + bob),
            elbowL: CGPoint(x: 0.50 - reach * 0.55, y: 0.335 + bob),
            handL: CGPoint(x: 0.50 - reach, y: 0.355 + bob),
            elbowR: CGPoint(x: 0.50 + reach * 0.55, y: 0.365 + bob),
            handR: CGPoint(x: 0.50 + reach, y: 0.385 + bob),
            kneeL: CGPoint(x: 0.455, y: 0.72),
            footL: CGPoint(x: 0.45, y: 0.92),
            kneeR: CGPoint(x: 0.545, y: 0.72),
            footR: CGPoint(x: 0.55, y: 0.92),
            arrows: [MotionArrow(from: CGPoint(x: 0.22, y: 0.36), to: CGPoint(x: 0.34, y: 0.36))]
        )
    }

    static func lunge(_ p: Double, stepLength: Double) -> StickPose {
        let (ping, isFirstHalf) = motionHalfCycle(p)
        let drop = 0.11 * ping
        let hip = CGPoint(x: 0.50, y: 0.52 + drop)
        let frontFoot = CGPoint(x: 0.50 - 0.13 * stepLength, y: 0.92)
        let backFoot = CGPoint(x: 0.50 + 0.17 * stepLength, y: 0.90 - 0.02 * ping)
        let pose = StickPose(
            head: CGPoint(x: 0.50, y: 0.15 + drop),
            neck: CGPoint(x: 0.50, y: 0.25 + drop),
            hip: hip,
            elbowL: CGPoint(x: 0.395, y: 0.38 + drop),
            handL: CGPoint(x: 0.385, y: 0.50 + drop),
            elbowR: CGPoint(x: 0.605, y: 0.38 + drop),
            handR: CGPoint(x: 0.615, y: 0.50 + drop),
            kneeL: CGPoint(x: 0.50 - 0.145 * stepLength, y: (hip.y + frontFoot.y) / 2),
            footL: frontFoot,
            kneeR: CGPoint(x: 0.50 + 0.10 * stepLength, y: 0.70 + drop * 1.3),
            footR: backFoot,
            arrows: [MotionArrow(from: CGPoint(x: 0.24, y: 0.52), to: CGPoint(x: 0.24, y: 0.66))]
        )
        return isFirstHalf ? pose : pose.mirrored()
    }

    static func wallSit(_ p: Double) -> StickPose {
        let breath = motionWave01(p)
        return StickPose(
            head: CGPoint(x: 0.375, y: 0.32),
            neck: CGPoint(x: 0.355, y: 0.42),
            hip: CGPoint(x: 0.33, y: 0.60),
            elbowL: CGPoint(x: 0.42, y: 0.52),
            handL: CGPoint(x: 0.52, y: 0.585),
            elbowR: CGPoint(x: 0.44, y: 0.545),
            handR: CGPoint(x: 0.54, y: 0.615),
            kneeL: CGPoint(x: 0.60, y: 0.595),
            footL: CGPoint(x: 0.605, y: 0.92),
            kneeR: CGPoint(x: 0.62, y: 0.625),
            footR: CGPoint(x: 0.625, y: 0.92),
            breathing: breath
        )
    }

    static func calfRaise(_ p: Double) -> StickPose {
        let lift = 0.055 * motionWave01(p)
        return StickPose(
            head: CGPoint(x: 0.44, y: 0.15 - lift),
            neck: CGPoint(x: 0.44, y: 0.25 - lift),
            hip: CGPoint(x: 0.44, y: 0.52 - lift),
            elbowL: CGPoint(x: 0.55, y: 0.40 - lift * 0.5),
            handL: CGPoint(x: 0.685, y: 0.545),
            elbowR: CGPoint(x: 0.575, y: 0.425 - lift * 0.5),
            handR: CGPoint(x: 0.705, y: 0.555),
            kneeL: CGPoint(x: 0.425, y: 0.72 - lift),
            footL: CGPoint(x: 0.415, y: 0.92),
            kneeR: CGPoint(x: 0.465, y: 0.72 - lift),
            footR: CGPoint(x: 0.455, y: 0.92),
            arrows: [MotionArrow(from: CGPoint(x: 0.25, y: 0.72), to: CGPoint(x: 0.25, y: 0.58))]
        )
    }

    static func quadStretch(_ p: Double) -> StickPose {
        let pull = motionWave01(p)
        let foot = motionLerp(CGPoint(x: 0.505, y: 0.92), CGPoint(x: 0.465, y: 0.635), pull)
        return StickPose(
            head: CGPoint(x: 0.42, y: 0.15),
            neck: CGPoint(x: 0.42, y: 0.25),
            hip: CGPoint(x: 0.42, y: 0.52),
            elbowL: CGPoint(x: 0.56, y: 0.40),
            handL: CGPoint(x: 0.695, y: 0.545),
            elbowR: CGPoint(x: 0.50, y: 0.545),
            handR: CGPoint(x: foot.x + 0.025, y: foot.y - 0.02),
            kneeL: CGPoint(x: 0.405, y: 0.72),
            footL: CGPoint(x: 0.40, y: 0.92),
            kneeR: CGPoint(x: 0.455, y: 0.735),
            footR: foot,
            arrows: [MotionArrow(from: CGPoint(x: 0.60, y: 0.86), to: CGPoint(x: 0.56, y: 0.72))]
        )
    }

    /// Half-kneeling, seen from the side: the back knee rests on the mat and
    /// the hips ease forward to open the front of the back hip.
    static func hipFlexorStretch(_ p: Double) -> StickPose {
        let shift = 0.045 * motionWave01(p)
        return StickPose(
            head: CGPoint(x: 0.47 - shift, y: 0.24),
            neck: CGPoint(x: 0.47 - shift, y: 0.34),
            hip: CGPoint(x: 0.51 - shift, y: 0.61),
            elbowL: CGPoint(x: 0.42 - shift, y: 0.47),
            handL: CGPoint(x: 0.40 - shift * 0.6, y: 0.61),
            elbowR: CGPoint(x: 0.54 - shift, y: 0.47),
            handR: CGPoint(x: 0.51 - shift, y: 0.59),
            kneeL: CGPoint(x: 0.34 - shift * 0.3, y: 0.66),
            footL: CGPoint(x: 0.33, y: 0.92),
            kneeR: CGPoint(x: 0.64 - shift * 0.5, y: 0.915),
            footR: CGPoint(x: 0.82, y: 0.915),
            arrows: [MotionArrow(from: CGPoint(x: 0.66, y: 0.52), to: CGPoint(x: 0.56, y: 0.52))]
        )
    }

    /// Standing, seen from the front: one arm reaches over the head and the
    /// torso bends gently towards the other side.
    static func sideStretch(_ p: Double) -> StickPose {
        let bend = motionWave01(p)
        return StickPose(
            head: CGPoint(x: 0.50 - 0.09 * bend, y: 0.15 + 0.02 * bend),
            neck: CGPoint(x: 0.50 - 0.055 * bend, y: 0.25 + 0.01 * bend),
            hip: CGPoint(x: 0.50, y: 0.52),
            elbowL: CGPoint(x: 0.42 - 0.03 * bend, y: 0.38),
            handL: CGPoint(x: 0.41 - 0.03 * bend, y: 0.50),
            elbowR: CGPoint(x: 0.57 - 0.06 * bend, y: 0.16),
            handR: CGPoint(x: 0.50 - 0.13 * bend, y: 0.07 + 0.03 * bend),
            kneeL: CGPoint(x: 0.455, y: 0.72),
            footL: CGPoint(x: 0.45, y: 0.92),
            kneeR: CGPoint(x: 0.545, y: 0.72),
            footR: CGPoint(x: 0.55, y: 0.92),
            arrows: [MotionArrow(from: CGPoint(x: 0.68, y: 0.16), to: CGPoint(x: 0.60, y: 0.09))]
        )
    }
}
