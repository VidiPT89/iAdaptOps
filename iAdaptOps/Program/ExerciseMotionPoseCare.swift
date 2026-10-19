import CoreGraphics
import Foundation

/// Poses for the care exercises. Seated ones are drawn from the side, facing
/// right, on a chair whose seat sits just under the hip (y ≈ 0.62).
extension ExerciseMotionPose {
    /// Sitting upright with feet flat and hands resting on the thighs.
    private static func seated(
        lean: Double = 0,
        handsOnBelly: Bool = false
    ) -> StickPose {
        let neck = CGPoint(x: 0.43 + lean, y: 0.33)
        let hands = handsOnBelly ? CGPoint(x: 0.47 + lean * 0.5, y: 0.52) : CGPoint(x: 0.55, y: 0.57)
        return StickPose(
            head: CGPoint(x: 0.43 + lean * 1.4, y: 0.23),
            neck: neck,
            hip: CGPoint(x: 0.44, y: 0.60),
            elbowL: CGPoint(x: 0.46 + lean, y: 0.46),
            handL: hands,
            elbowR: CGPoint(x: 0.47 + lean, y: 0.47),
            handR: CGPoint(x: hands.x + 0.01, y: hands.y + 0.01),
            kneeL: CGPoint(x: 0.60, y: 0.60),
            footL: CGPoint(x: 0.61, y: 0.92),
            kneeR: CGPoint(x: 0.62, y: 0.61),
            footR: CGPoint(x: 0.63, y: 0.92)
        )
    }

    static func seatedMarch(_ p: Double) -> StickPose {
        let s = motionWave(p)
        let liftL = max(0, s)
        let liftR = max(0, -s)
        var pose = seated()
        pose.kneeL = CGPoint(x: 0.60, y: 0.60 - 0.10 * liftL)
        pose.footL = CGPoint(x: 0.62, y: 0.92 - 0.12 * liftL)
        pose.kneeR = CGPoint(x: 0.62, y: 0.61 - 0.10 * liftR)
        pose.footR = CGPoint(x: 0.64, y: 0.92 - 0.12 * liftR)
        pose.handL = CGPoint(x: 0.55, y: 0.55 - 0.05 * liftR)
        pose.handR = CGPoint(x: 0.56, y: 0.56 - 0.05 * liftL)
        pose.arrows = [MotionArrow(from: CGPoint(x: 0.80, y: 0.86), to: CGPoint(x: 0.80, y: 0.72))]
        return pose
    }

    static func seatedKneeExtension(_ p: Double) -> StickPose {
        let (ping, isFirstHalf) = motionHalfCycle(p)
        var pose = seated()
        let extended = CGPoint(x: 0.80, y: 0.61)
        pose.footL = motionLerp(CGPoint(x: 0.61, y: 0.92), extended, isFirstHalf ? ping : 0)
        pose.footR = motionLerp(CGPoint(x: 0.63, y: 0.92), CGPoint(x: 0.82, y: 0.62), isFirstHalf ? 0 : ping)
        pose.arrows = [MotionArrow(from: CGPoint(x: 0.70, y: 0.84), to: CGPoint(x: 0.80, y: 0.72))]
        return pose
    }

    static func sitToStand(_ p: Double) -> StickPose {
        let up = motionWave01(p)
        func mix(_ a: CGPoint, _ b: CGPoint) -> CGPoint { motionLerp(a, b, up) }
        let neck = mix(CGPoint(x: 0.50, y: 0.36), CGPoint(x: 0.53, y: 0.25))
        return StickPose(
            head: mix(CGPoint(x: 0.55, y: 0.27), CGPoint(x: 0.54, y: 0.15)),
            neck: neck,
            hip: mix(CGPoint(x: 0.44, y: 0.60), CGPoint(x: 0.52, y: 0.52)),
            elbowL: CGPoint(x: neck.x + 0.05, y: neck.y + 0.09),
            handL: CGPoint(x: neck.x + 0.06, y: neck.y + 0.03),
            elbowR: CGPoint(x: neck.x + 0.06, y: neck.y + 0.10),
            handR: CGPoint(x: neck.x + 0.07, y: neck.y + 0.04),
            kneeL: mix(CGPoint(x: 0.60, y: 0.60), CGPoint(x: 0.55, y: 0.72)),
            footL: CGPoint(x: 0.60, y: 0.92),
            kneeR: mix(CGPoint(x: 0.62, y: 0.61), CGPoint(x: 0.57, y: 0.72)),
            footR: CGPoint(x: 0.62, y: 0.92),
            arrows: [MotionArrow(from: CGPoint(x: 0.76, y: 0.52), to: CGPoint(x: 0.76, y: 0.36))]
        )
    }

    /// Leaning into a wall on the left, hands flat on it at shoulder height.
    static func wallPushUp(_ p: Double) -> StickPose {
        let bend = motionWave01(p)
        let shift = 0.07 * bend
        return StickPose(
            head: CGPoint(x: 0.49 - shift, y: 0.20),
            neck: CGPoint(x: 0.52 - shift, y: 0.28),
            hip: CGPoint(x: 0.61 - shift * 0.5, y: 0.57),
            elbowL: CGPoint(x: 0.40 - shift * 0.5, y: 0.34 + 0.07 * bend),
            handL: CGPoint(x: 0.285, y: 0.29),
            elbowR: CGPoint(x: 0.41 - shift * 0.5, y: 0.37 + 0.07 * bend),
            handR: CGPoint(x: 0.285, y: 0.33),
            kneeL: CGPoint(x: 0.66 - shift * 0.2, y: 0.75),
            footL: CGPoint(x: 0.70, y: 0.92),
            kneeR: CGPoint(x: 0.68 - shift * 0.2, y: 0.75),
            footR: CGPoint(x: 0.72, y: 0.92),
            arrows: [MotionArrow(from: CGPoint(x: 0.62, y: 0.14), to: CGPoint(x: 0.52, y: 0.14))]
        )
    }

    static func shoulderRoll(_ p: Double) -> StickPose {
        let theta = p * 2 * .pi
        var pose = seated()
        pose.neck = CGPoint(x: 0.43 + 0.018 * cos(theta), y: 0.33 + 0.018 * sin(theta))
        pose.head = CGPoint(x: 0.43 + 0.008 * cos(theta), y: 0.23 + 0.006 * sin(theta))
        pose.elbowL = CGPoint(x: 0.45 + 0.012 * cos(theta), y: 0.46 + 0.012 * sin(theta))
        pose.elbowR = CGPoint(x: 0.46 + 0.012 * cos(theta), y: 0.47 + 0.012 * sin(theta))
        pose.arrows = [MotionArrow(from: CGPoint(x: 0.30, y: 0.36), to: CGPoint(x: 0.34, y: 0.28))]
        return pose
    }

    /// Hands on the belly while a slow halo shows the breath.
    static func breathing(_ p: Double) -> StickPose {
        let breath = motionWave01(p)
        var pose = seated(handsOnBelly: true)
        pose.neck.y -= 0.01 * breath
        pose.head.y -= 0.01 * breath
        pose.breathing = breath
        return pose
    }

    static func seatedCatCow(_ p: Double) -> StickPose {
        let w = motionWave(p)
        var pose = seated(lean: 0.03 * w)
        pose.neck.y += 0.02 * abs(w)
        pose.head.y += 0.03 * max(0, -w)
        pose.handL = CGPoint(x: 0.59, y: 0.59)
        pose.handR = CGPoint(x: 0.60, y: 0.60)
        pose.arrows = [MotionArrow(from: CGPoint(x: 0.30, y: 0.30), to: CGPoint(x: 0.30, y: 0.44))]
        return pose
    }

    /// Seen from the front: arms crossed on the chest, the torso turns.
    static func seatedRotation(_ p: Double) -> StickPose {
        let r = motionWave(p)
        return StickPose(
            head: CGPoint(x: 0.50 + 0.03 * r, y: 0.23),
            neck: CGPoint(x: 0.50 + 0.01 * r, y: 0.33),
            hip: CGPoint(x: 0.50, y: 0.60),
            elbowL: CGPoint(x: 0.43 + 0.06 * r, y: 0.43),
            handL: CGPoint(x: 0.55 + 0.03 * r, y: 0.37),
            elbowR: CGPoint(x: 0.57 + 0.06 * r, y: 0.43),
            handR: CGPoint(x: 0.45 + 0.03 * r, y: 0.37),
            kneeL: CGPoint(x: 0.42, y: 0.66),
            footL: CGPoint(x: 0.42, y: 0.92),
            kneeR: CGPoint(x: 0.58, y: 0.66),
            footR: CGPoint(x: 0.58, y: 0.92),
            arrows: [MotionArrow(from: CGPoint(x: 0.36, y: 0.20), to: CGPoint(x: 0.64, y: 0.20))]
        )
    }

    /// Hands on the chair, one foot lifts just off the floor, then the other.
    static func supportedBalance(_ p: Double) -> StickPose {
        let (ping, isFirstHalf) = motionHalfCycle(p)
        var pose = calfRaise(0)
        let lift = 0.09 * ping
        if isFirstHalf {
            pose.kneeL = CGPoint(x: 0.43, y: 0.72 - lift * 0.8)
            pose.footL = CGPoint(x: 0.41, y: 0.92 - lift)
        } else {
            pose.kneeR = CGPoint(x: 0.47, y: 0.72 - lift * 0.8)
            pose.footR = CGPoint(x: 0.46, y: 0.92 - lift)
        }
        pose.arrows = [MotionArrow(from: CGPoint(x: 0.25, y: 0.90), to: CGPoint(x: 0.25, y: 0.78))]
        return pose
    }

    /// Hands on the chair, the far leg lifts out to the side and back.
    static func standingHipAbduction(_ p: Double) -> StickPose {
        let out = motionWave01(p)
        var pose = calfRaise(0)
        pose.kneeL = motionLerp(CGPoint(x: 0.425, y: 0.72), CGPoint(x: 0.38, y: 0.71), out)
        pose.footL = motionLerp(CGPoint(x: 0.415, y: 0.92), CGPoint(x: 0.31, y: 0.86), out)
        pose.head.x += 0.01 * out
        pose.neck.x += 0.01 * out
        pose.arrows = [MotionArrow(from: CGPoint(x: 0.34, y: 0.95), to: CGPoint(x: 0.22, y: 0.88))]
        return pose
    }
}
