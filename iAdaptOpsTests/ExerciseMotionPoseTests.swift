import CoreGraphics
import XCTest
@testable import iAdaptOps

final class ExerciseMotionPoseTests: XCTestCase {
    private let samplePhases: [Double] = stride(from: 0, to: 1, by: 0.05).map { $0 }

    func testEveryJointStaysInsideTheDrawingArea() {
        for kind in ExerciseMotionKind.allCases {
            for phase in samplePhases {
                let pose = ExerciseMotionPose.pose(for: kind, phase: phase)
                for joint in pose.joints {
                    XCTAssertTrue(
                        (0...1).contains(joint.x) && (0...1).contains(joint.y),
                        "\(kind.rawValue) at phase \(phase) has a joint outside 0...1: \(joint)"
                    )
                }
            }
        }
    }

    func testArrowsStayInsideTheDrawingArea() {
        for kind in ExerciseMotionKind.allCases {
            for phase in samplePhases {
                let pose = ExerciseMotionPose.pose(for: kind, phase: phase)
                for arrow in pose.arrows {
                    for point in [arrow.from, arrow.to] {
                        XCTAssertTrue(
                            (0...1).contains(point.x) && (0...1).contains(point.y),
                            "\(kind.rawValue) arrow leaves the canvas at \(point)"
                        )
                    }
                }
            }
        }
    }

    func testFloorExercisesReportHorizontalAndStandingOnesDoNot() {
        let floor: Set<ExerciseMotionKind> = [
            .sideLegRaise, .bridge, .marchingBridge, .birdDog, .deadBug,
            .heelTap, .pelvicTilt, .childsPose, .figureFour, .hamstringStretch
        ]
        for kind in ExerciseMotionKind.allCases {
            let pose = ExerciseMotionPose.pose(for: kind, phase: 0.3)
            XCTAssertEqual(pose.horizontal, floor.contains(kind), "\(kind.rawValue) orientation")
            XCTAssertEqual(kind.isHorizontal, floor.contains(kind), "\(kind.rawValue) declared orientation")
        }
    }

    func testEveryMotionActuallyMoves() {
        for kind in ExerciseMotionKind.allCases {
            let poses = [0, 0.25, 0.5, 0.75].map { ExerciseMotionPose.pose(for: kind, phase: $0) }
            var largestTravel: CGFloat = 0
            var largestBreathChange: Double = 0

            for a in poses {
                for b in poses {
                    for (first, second) in zip(a.joints, b.joints) {
                        largestTravel = max(largestTravel, hypot(first.x - second.x, first.y - second.y))
                    }
                    largestBreathChange = max(largestBreathChange, abs(a.breathing - b.breathing))
                }
            }

            XCTAssertTrue(
                largestTravel > 0.005 || largestBreathChange > 0.1,
                "\(kind.rawValue) looks frozen: travel \(largestTravel), breath \(largestBreathChange)"
            )
        }
    }

    func testPhaseWrapsAroundSoTheLoopIsSeamless() {
        for kind in ExerciseMotionKind.allCases {
            let start = ExerciseMotionPose.pose(for: kind, phase: 0)
            let wrapped = ExerciseMotionPose.pose(for: kind, phase: 1)
            let overWrapped = ExerciseMotionPose.pose(for: kind, phase: 2.0)
            XCTAssertEqual(start, wrapped, "\(kind.rawValue) does not wrap at 1")
            XCTAssertEqual(start, overWrapped, "\(kind.rawValue) does not wrap at 2")
        }
    }

    func testOnlyIsometricHoldsBreathe() {
        for kind in ExerciseMotionKind.allCases {
            let breathes = samplePhases.contains { ExerciseMotionPose.pose(for: kind, phase: $0).breathing > 0 }
            XCTAssertEqual(breathes, kind.hasBreathingGlow, "\(kind.rawValue) breathing glow")
        }
    }

    func testMirroringSwapsSidesAndKeepsTheFigureOnCanvas() {
        let pose = ExerciseMotionPose.pose(for: .birdDog, phase: 0.2)
        let mirrored = pose.mirrored()
        XCTAssertEqual(mirrored.handL.x, 1 - pose.handR.x, accuracy: 0.0001)
        XCTAssertEqual(mirrored.handL.y, pose.handR.y, accuracy: 0.0001)
        XCTAssertEqual(mirrored.hip.x, 1 - pose.hip.x, accuracy: 0.0001)

        let restored = mirrored.mirrored()
        for (original, roundTripped) in zip(pose.joints, restored.joints) {
            XCTAssertEqual(roundTripped.x, original.x, accuracy: 0.0001)
            XCTAssertEqual(roundTripped.y, original.y, accuracy: 0.0001)
        }
    }

    func testAlternatingMotionsShowBothSides() {
        for kind in [ExerciseMotionKind.lunge, .shortLunge, .birdDog, .marchingBridge, .heelTap, .deadBug] {
            let first = ExerciseMotionPose.pose(for: kind, phase: 0.25)
            let second = ExerciseMotionPose.pose(for: kind, phase: 0.75)
            XCTAssertNotEqual(first, second, "\(kind.rawValue) looks identical on both halves of the cycle")
        }
    }

    func testKeyPoseIsUsedWhenMotionIsReduced() {
        for kind in ExerciseMotionKind.allCases {
            let key = ExerciseMotionPose.keyPose(for: kind)
            XCTAssertEqual(key, ExerciseMotionPose.pose(for: kind, phase: 0.25))
            for joint in key.joints {
                XCTAssertTrue((0...1).contains(joint.x) && (0...1).contains(joint.y))
            }
        }
    }

    func testPulsedSquatTravelsLessThanAFullSquat() {
        func hipTravel(_ kind: ExerciseMotionKind) -> CGFloat {
            let values = samplePhases.map { ExerciseMotionPose.pose(for: kind, phase: $0).hip.y }
            return (values.max() ?? 0) - (values.min() ?? 0)
        }
        XCTAssertLessThan(hipTravel(.pulseSquat), hipTravel(.squat))
    }

    func testGentleVariantsMoveLessThanTheFullOnes() {
        func hipTravel(_ kind: ExerciseMotionKind) -> CGFloat {
            let values = samplePhases.map { ExerciseMotionPose.pose(for: kind, phase: $0).hip.y }
            return (values.max() ?? 0) - (values.min() ?? 0)
        }
        XCTAssertLessThan(hipTravel(.gentleSquat), hipTravel(.squat))

        func stride(_ kind: ExerciseMotionKind) -> CGFloat {
            let pose = ExerciseMotionPose.pose(for: kind, phase: 0.25)
            return abs(pose.footR.x - pose.footL.x)
        }
        XCTAssertLessThan(stride(.shortLunge), stride(.lunge))
    }

    func testSumoSquatStandsWiderThanAPlainSquat() {
        let sumo = ExerciseMotionPose.pose(for: .sumoSquat, phase: 0.25)
        let squat = ExerciseMotionPose.pose(for: .squat, phase: 0.25)
        XCTAssertGreaterThan(sumo.footR.x - sumo.footL.x, squat.footR.x - squat.footL.x)
    }
}
