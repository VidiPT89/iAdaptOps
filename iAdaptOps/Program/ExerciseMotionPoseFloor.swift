import CoreGraphics
import Foundation

/// Poses for the exercises done lying down or on all fours. They share a
/// common baseline: the mat sits at y ≈ 0.88 and the body runs along the
/// x-axis with the head towards the leading edge.
extension ExerciseMotionPose {
    static func sideLegRaise(_ p: Double) -> StickPose {
        let lift = motionWave01(p)
        return StickPose(
            head: CGPoint(x: 0.17, y: 0.66),
            neck: CGPoint(x: 0.27, y: 0.71),
            hip: CGPoint(x: 0.55, y: 0.78),
            elbowL: CGPoint(x: 0.18, y: 0.79),
            handL: CGPoint(x: 0.08, y: 0.82),
            elbowR: CGPoint(x: 0.42, y: 0.82),
            handR: CGPoint(x: 0.45, y: 0.855),
            kneeL: CGPoint(x: 0.72, y: 0.80),
            footL: CGPoint(x: 0.64, y: 0.855),
            kneeR: motionLerp(CGPoint(x: 0.74, y: 0.755), CGPoint(x: 0.71, y: 0.56), lift),
            footR: motionLerp(CGPoint(x: 0.91, y: 0.77), CGPoint(x: 0.87, y: 0.40), lift),
            horizontal: true,
            arrows: [MotionArrow(from: CGPoint(x: 0.94, y: 0.66), to: CGPoint(x: 0.94, y: 0.48))]
        )
    }

    static func bridge(_ p: Double) -> StickPose {
        let rise = motionWave01(p)
        return StickPose(
            head: CGPoint(x: 0.17, y: 0.80),
            neck: CGPoint(x: 0.28, y: 0.80),
            hip: CGPoint(x: 0.50, y: 0.78 - 0.17 * rise),
            elbowL: CGPoint(x: 0.34, y: 0.845),
            handL: CGPoint(x: 0.46, y: 0.858),
            elbowR: CGPoint(x: 0.36, y: 0.862),
            handR: CGPoint(x: 0.48, y: 0.872),
            kneeL: CGPoint(x: 0.685, y: 0.615 - 0.03 * rise),
            footL: CGPoint(x: 0.71, y: 0.87),
            kneeR: CGPoint(x: 0.725, y: 0.638 - 0.03 * rise),
            footR: CGPoint(x: 0.75, y: 0.87),
            horizontal: true,
            arrows: [MotionArrow(from: CGPoint(x: 0.50, y: 0.50), to: CGPoint(x: 0.50, y: 0.36))]
        )
    }

    static func marchingBridge(_ p: Double) -> StickPose {
        let (ping, isFirstHalf) = motionHalfCycle(p)
        let liftedKnee = motionLerp(CGPoint(x: 0.685, y: 0.60), CGPoint(x: 0.645, y: 0.52), ping)
        let liftedFoot = motionLerp(CGPoint(x: 0.71, y: 0.87), CGPoint(x: 0.725, y: 0.735), ping)
        let restingKnee = CGPoint(x: 0.728, y: 0.625)
        let restingFoot = CGPoint(x: 0.755, y: 0.87)
        return StickPose(
            head: CGPoint(x: 0.17, y: 0.80),
            neck: CGPoint(x: 0.28, y: 0.80),
            hip: CGPoint(x: 0.50, y: 0.615),
            elbowL: CGPoint(x: 0.34, y: 0.845),
            handL: CGPoint(x: 0.46, y: 0.858),
            elbowR: CGPoint(x: 0.36, y: 0.862),
            handR: CGPoint(x: 0.48, y: 0.872),
            kneeL: isFirstHalf ? liftedKnee : restingKnee,
            footL: isFirstHalf ? liftedFoot : restingFoot,
            kneeR: isFirstHalf ? restingKnee : liftedKnee,
            footR: isFirstHalf ? restingFoot : liftedFoot,
            horizontal: true,
            arrows: [MotionArrow(from: CGPoint(x: 0.86, y: 0.84), to: CGPoint(x: 0.86, y: 0.72))]
        )
    }

    static func birdDog(_ p: Double) -> StickPose {
        let (ext, isFirstHalf) = motionHalfCycle(p)
        let pose = StickPose(
            head: CGPoint(x: 0.235, y: 0.545),
            neck: CGPoint(x: 0.34, y: 0.565),
            hip: CGPoint(x: 0.64, y: 0.585),
            elbowL: motionLerp(CGPoint(x: 0.335, y: 0.70), CGPoint(x: 0.24, y: 0.51), ext),
            handL: motionLerp(CGPoint(x: 0.345, y: 0.86), CGPoint(x: 0.12, y: 0.47), ext),
            elbowR: CGPoint(x: 0.365, y: 0.715),
            handR: CGPoint(x: 0.375, y: 0.865),
            kneeL: CGPoint(x: 0.645, y: 0.725),
            footL: CGPoint(x: 0.655, y: 0.865),
            kneeR: motionLerp(CGPoint(x: 0.625, y: 0.72), CGPoint(x: 0.78, y: 0.535), ext),
            footR: motionLerp(CGPoint(x: 0.635, y: 0.86), CGPoint(x: 0.92, y: 0.47), ext),
            horizontal: true,
            arrows: [MotionArrow(from: CGPoint(x: 0.14, y: 0.66), to: CGPoint(x: 0.08, y: 0.58))]
        )
        return isFirstHalf ? pose : pose.mirrored()
    }

    static func deadBug(_ p: Double) -> StickPose {
        let (ext, _) = motionHalfCycle(p)
        let swapped = p >= 0.5
        let movingElbow = motionLerp(CGPoint(x: 0.325, y: 0.665), CGPoint(x: 0.235, y: 0.705), ext)
        let movingHand = motionLerp(CGPoint(x: 0.345, y: 0.525), CGPoint(x: 0.125, y: 0.665), ext)
        let stillElbow = CGPoint(x: 0.36, y: 0.688)
        let stillHand = CGPoint(x: 0.378, y: 0.548)
        let movingKnee = motionLerp(CGPoint(x: 0.655, y: 0.615), CGPoint(x: 0.70, y: 0.715), ext)
        let movingFoot = motionLerp(CGPoint(x: 0.785, y: 0.632), CGPoint(x: 0.925, y: 0.805), ext)
        let stillKnee = CGPoint(x: 0.628, y: 0.592)
        let stillFoot = CGPoint(x: 0.758, y: 0.608)
        return StickPose(
            head: CGPoint(x: 0.205, y: 0.79),
            neck: CGPoint(x: 0.31, y: 0.788),
            hip: CGPoint(x: 0.56, y: 0.782),
            elbowL: swapped ? stillElbow : movingElbow,
            handL: swapped ? stillHand : movingHand,
            elbowR: swapped ? movingElbow : stillElbow,
            handR: swapped ? movingHand : stillHand,
            kneeL: swapped ? movingKnee : stillKnee,
            footL: swapped ? movingFoot : stillFoot,
            kneeR: swapped ? stillKnee : movingKnee,
            footR: swapped ? stillFoot : movingFoot,
            horizontal: true,
            arrows: [MotionArrow(from: CGPoint(x: 0.50, y: 0.44), to: CGPoint(x: 0.38, y: 0.50))]
        )
    }

    static func heelTap(_ p: Double) -> StickPose {
        let (tap, isFirstHalf) = motionHalfCycle(p)
        let tappingKnee = motionLerp(CGPoint(x: 0.655, y: 0.625), CGPoint(x: 0.685, y: 0.665), tap)
        let tappingFoot = motionLerp(CGPoint(x: 0.785, y: 0.642), CGPoint(x: 0.875, y: 0.865), tap)
        let holdingKnee = CGPoint(x: 0.628, y: 0.598)
        let holdingFoot = CGPoint(x: 0.758, y: 0.615)
        return StickPose(
            head: CGPoint(x: 0.18, y: 0.79),
            neck: CGPoint(x: 0.285, y: 0.788),
            hip: CGPoint(x: 0.525, y: 0.782),
            elbowL: CGPoint(x: 0.335, y: 0.828),
            handL: CGPoint(x: 0.445, y: 0.848),
            elbowR: CGPoint(x: 0.355, y: 0.848),
            handR: CGPoint(x: 0.465, y: 0.866),
            kneeL: isFirstHalf ? tappingKnee : holdingKnee,
            footL: isFirstHalf ? tappingFoot : holdingFoot,
            kneeR: isFirstHalf ? holdingKnee : tappingKnee,
            footR: isFirstHalf ? holdingFoot : tappingFoot,
            horizontal: true,
            arrows: [MotionArrow(from: CGPoint(x: 0.90, y: 0.66), to: CGPoint(x: 0.90, y: 0.80))]
        )
    }

    static func pelvicTilt(_ p: Double) -> StickPose {
        let tilt = motionWave01(p)
        return StickPose(
            head: CGPoint(x: 0.18, y: 0.80),
            neck: CGPoint(x: 0.285, y: 0.796 + 0.012 * tilt),
            hip: CGPoint(x: 0.525, y: 0.806 - 0.032 * tilt),
            elbowL: CGPoint(x: 0.34, y: 0.838),
            handL: CGPoint(x: 0.45, y: 0.852),
            elbowR: CGPoint(x: 0.36, y: 0.856),
            handR: CGPoint(x: 0.47, y: 0.868),
            kneeL: CGPoint(x: 0.68, y: 0.628 - 0.012 * tilt),
            footL: CGPoint(x: 0.72, y: 0.87),
            kneeR: CGPoint(x: 0.715, y: 0.648 - 0.012 * tilt),
            footR: CGPoint(x: 0.755, y: 0.87),
            horizontal: true,
            arrows: [MotionArrow(from: CGPoint(x: 0.47, y: 0.70), to: CGPoint(x: 0.55, y: 0.74))]
        )
    }

    static func childsPose(_ p: Double) -> StickPose {
        let breath = motionWave01(p)
        return StickPose(
            head: CGPoint(x: 0.325, y: 0.795 - 0.008 * breath),
            neck: CGPoint(x: 0.44, y: 0.775 - 0.010 * breath),
            hip: CGPoint(x: 0.72, y: 0.702 - 0.014 * breath),
            elbowL: CGPoint(x: 0.305, y: 0.818),
            handL: CGPoint(x: 0.125, y: 0.848),
            elbowR: CGPoint(x: 0.328, y: 0.838),
            handR: CGPoint(x: 0.148, y: 0.864),
            kneeL: CGPoint(x: 0.745, y: 0.802),
            footL: CGPoint(x: 0.865, y: 0.848),
            kneeR: CGPoint(x: 0.772, y: 0.818),
            footR: CGPoint(x: 0.892, y: 0.862),
            horizontal: true,
            breathing: breath
        )
    }

    static func figureFour(_ p: Double) -> StickPose {
        let pull = motionWave01(p)
        let pulledKnee = motionLerp(CGPoint(x: 0.70, y: 0.625), CGPoint(x: 0.62, y: 0.50), pull)
        let pulledFoot = motionLerp(CGPoint(x: 0.765, y: 0.852), CGPoint(x: 0.705, y: 0.665), pull)
        return StickPose(
            head: CGPoint(x: 0.18, y: 0.805),
            neck: CGPoint(x: 0.285, y: 0.80),
            hip: CGPoint(x: 0.55, y: 0.792),
            elbowL: CGPoint(x: 0.44, y: 0.738),
            handL: motionLerp(CGPoint(x: 0.632, y: 0.715), CGPoint(x: 0.565, y: 0.592), pull),
            elbowR: CGPoint(x: 0.462, y: 0.768),
            handR: motionLerp(CGPoint(x: 0.652, y: 0.745), CGPoint(x: 0.585, y: 0.622), pull),
            kneeL: CGPoint(x: pulledKnee.x + 0.132, y: pulledKnee.y + 0.055),
            footL: CGPoint(x: pulledKnee.x - 0.018, y: pulledKnee.y - 0.028),
            kneeR: pulledKnee,
            footR: pulledFoot,
            horizontal: true,
            arrows: [MotionArrow(from: CGPoint(x: 0.80, y: 0.55), to: CGPoint(x: 0.70, y: 0.46))]
        )
    }

    static func hamstringStretch(_ p: Double) -> StickPose {
        let pull = motionWave01(p)
        return StickPose(
            head: CGPoint(x: 0.18, y: 0.822),
            neck: CGPoint(x: 0.285, y: 0.818),
            hip: CGPoint(x: 0.55, y: 0.812),
            elbowL: CGPoint(x: 0.425, y: 0.742),
            handL: motionLerp(CGPoint(x: 0.582, y: 0.602), CGPoint(x: 0.552, y: 0.548), pull),
            elbowR: CGPoint(x: 0.448, y: 0.768),
            handR: motionLerp(CGPoint(x: 0.602, y: 0.625), CGPoint(x: 0.572, y: 0.572), pull),
            kneeL: CGPoint(x: 0.705, y: 0.848),
            footL: CGPoint(x: 0.855, y: 0.862),
            kneeR: motionLerp(CGPoint(x: 0.632, y: 0.632), CGPoint(x: 0.588, y: 0.578), pull),
            footR: motionLerp(CGPoint(x: 0.702, y: 0.422), CGPoint(x: 0.622, y: 0.302), pull),
            horizontal: true,
            arrows: [MotionArrow(from: CGPoint(x: 0.82, y: 0.44), to: CGPoint(x: 0.76, y: 0.34))]
        )
    }
}
