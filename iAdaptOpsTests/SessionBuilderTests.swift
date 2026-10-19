import XCTest
@testable import iAdaptOps

final class SessionBuilderTests: XCTestCase {
    private func day(_ index: Int) -> ProgramDay {
        guard let day = ProgramData.days.first(where: { $0.index == index }) else {
            fatalError("Day \(index) should exist")
        }
        return day
    }

    // MARK: - Structure

    func testSessionOpensWithGetReadyAndTheWarmup() {
        let steps = SessionBuilder.steps(for: day(1))
        XCTAssertEqual(steps.first?.kind, .getReady)
        XCTAssertEqual(steps.first?.seconds, ProgramData.getReadySeconds)

        let warmup = steps.filter { $0.block == .warmup && $0.isWork }
        XCTAssertEqual(warmup.count, ProgramData.warmup.count)
        XCTAssertTrue(warmup.allSatisfy { $0.seconds == ProgramData.warmupSeconds })
        XCTAssertFalse(steps.contains { $0.block == .warmup && $0.isRest })
    }

    func testSessionClosesWithTheStretchingBlock() {
        let steps = SessionBuilder.steps(for: day(28))
        let cooldown = steps.suffix(ProgramData.cooldown.count)
        XCTAssertTrue(cooldown.allSatisfy { $0.block == .cooldown && $0.isWork })
        XCTAssertEqual(cooldown.reduce(0) { $0 + $1.seconds }, 120)
    }

    func testCircuitHasOneWorkIntervalPerExercisePerRound() {
        for index in [1, 9, 17, 28] {
            let day = day(index)
            let steps = SessionBuilder.steps(for: day)
            let work = steps.filter { $0.block == .workout && $0.isWork }
            XCTAssertEqual(work.count, day.exercises.count * day.params.rounds, "Day \(index)")
            XCTAssertTrue(work.allSatisfy { $0.seconds == day.params.work }, "Day \(index)")
        }
    }

    func testEveryWorkIntervalRestsExceptTheLastOne() {
        let day = day(1)
        let steps = SessionBuilder.steps(for: day)
        let work = steps.filter { $0.block == .workout && $0.isWork }.count
        let rest = steps.filter { $0.block == .workout && $0.isRest }.count
        XCTAssertEqual(rest, work - 1)
        XCTAssertEqual(steps.last?.block, .cooldown)
    }

    func testRestStepPreviewsTheNextExercise() {
        let day = day(1)
        let steps = SessionBuilder.steps(for: day)
        for (offset, step) in steps.enumerated() where step.isRest {
            let next = steps[(offset + 1)...].first { $0.isWork }
            XCTAssertEqual(step.ref, next?.ref, "Rest at \(offset) should preview the next exercise")
        }
    }

    func testRoundNumbersCountUp() {
        let day = day(17)
        let rounds = SessionBuilder.steps(for: day)
            .filter { $0.block == .workout }
            .map(\.round)
        XCTAssertEqual(Set(rounds), Set(1...day.params.rounds))
        XCTAssertEqual(rounds.first, 1)
        XCTAssertEqual(rounds.last, day.params.rounds)
    }

    // MARK: - Durations

    func testSessionsRunAboutSeventeenMinutesInWeeksOneToFour() {
        for index in [1, 5, 9, 16] {
            let minutes = SessionBuilder.estimatedMinutes(for: day(index))
            XCTAssertEqual(minutes, 17, "Day \(index) should be about 17 minutes, got \(minutes)")
        }
    }

    func testSessionsRunAboutTwentyOneMinutesInWeeksFiveToSeven() {
        for index in [17, 21, 25, 28] {
            let minutes = SessionBuilder.estimatedMinutes(for: day(index))
            XCTAssertEqual(minutes, 21, "Day \(index) should be about 21 minutes, got \(minutes)")
        }
    }

    func testTotalSecondsAddUpFromTheParameters() {
        let day = day(1)
        let params = day.params
        let circuit = day.exercises.count * params.rounds
        let expected = ProgramData.getReadySeconds
            + ProgramData.warmup.count * ProgramData.warmupSeconds
            + circuit * params.work
            + (circuit - 1) * params.rest
            + 120
        XCTAssertEqual(SessionBuilder.totalSeconds(for: day), expected)
    }

    // MARK: - Unilateral work

    func testUnilateralWorkSplitsDownTheMiddle() {
        let steps = SessionBuilder.steps(for: day(1))
        let sideRaises = steps.filter { $0.isWork && $0.ref.exercise == .sideLegRaise }
        XCTAssertFalse(sideRaises.isEmpty)
        for step in sideRaises {
            XCTAssertEqual(step.switchSideAtSecond, step.seconds / 2)
        }
    }

    func testBilateralWorkNeverAsksForASideSwitch() {
        let steps = SessionBuilder.steps(for: day(1))
        let bridges = steps.filter { $0.isWork && $0.ref.exercise == .gluteBridge }
        XCTAssertFalse(bridges.isEmpty)
        XCTAssertTrue(bridges.allSatisfy { $0.switchSideAtSecond == nil })
    }

    func testRestStepsNeverAskForASideSwitch() {
        let steps = SessionBuilder.steps(for: day(1))
        XCTAssertTrue(steps.filter(\.isRest).allSatisfy { $0.switchSideAtSecond == nil })
    }

    // MARK: - Low-energy day

    func testLowEnergyDropsARoundAndRebalancesTheTiming() {
        let day = day(1)
        let normal = day.params
        let eased = SessionBuilder.params(for: day, lowEnergy: true)
        XCTAssertEqual(eased.rounds, normal.rounds - 1)
        XCTAssertEqual(eased.work, normal.work - 10)
        XCTAssertEqual(eased.rest, normal.rest + 10)
    }

    func testLowEnergyNeverGoesBelowTwoRounds() {
        for index in 1...ProgramData.totalDays {
            let eased = SessionBuilder.params(for: day(index), lowEnergy: true)
            XCTAssertGreaterThanOrEqual(eased.rounds, 2, "Day \(index)")
            XCTAssertGreaterThanOrEqual(eased.work, 20, "Day \(index)")
        }
    }

    func testLowEnergyRemovesTheBottles() {
        let loaded = day(13)
        XCTAssertTrue(loaded.exercises.contains { $0.modifiers.contains(.weighted) })

        let steps = SessionBuilder.steps(for: loaded, lowEnergy: true)
        XCTAssertFalse(steps.contains { $0.ref.modifiers.contains(.weighted) })
    }

    func testLowEnergyKeepsTheOtherModifiers() {
        let steps = SessionBuilder.steps(for: day(13), lowEnergy: true)
        XCTAssertTrue(steps.contains { $0.ref.modifiers.contains(.pulse) })
    }

    func testLowEnergySessionIsShorterButKeepsWarmupAndStretching() {
        let day = day(17)
        XCTAssertLessThan(
            SessionBuilder.totalSeconds(for: day, lowEnergy: true),
            SessionBuilder.totalSeconds(for: day)
        )

        let steps = SessionBuilder.steps(for: day, lowEnergy: true)
        XCTAssertEqual(steps.filter { $0.block == .warmup && $0.isWork }.count, ProgramData.warmup.count)
        XCTAssertEqual(steps.filter { $0.block == .cooldown }.count, ProgramData.cooldown.count)
    }

    // MARK: - Invariants across the whole program

    func testEveryDayProducesAPlayableSession() {
        for index in 1...ProgramData.totalDays {
            for lowEnergy in [false, true] {
                let steps = SessionBuilder.steps(for: day(index), lowEnergy: lowEnergy)
                XCTAssertFalse(steps.isEmpty, "Day \(index)")
                XCTAssertTrue(steps.allSatisfy { $0.seconds > 0 }, "Day \(index) has a zero-length step")
                XCTAssertEqual(steps.map(\.id), Array(0..<steps.count), "Day \(index) step ids")
            }
        }
    }
}
