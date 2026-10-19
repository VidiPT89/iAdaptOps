import XCTest
@testable import iAdaptOps

final class ProgramDataTests: XCTestCase {
    func testProgramHasTwentyEightDays() {
        XCTAssertEqual(ProgramData.days.count, 28)
        XCTAssertEqual(ProgramData.totalDays, 28)
    }

    func testDayIndicesAreSequential() {
        for (offset, day) in ProgramData.days.enumerated() {
            XCTAssertEqual(day.index, offset + 1)
        }
    }

    func testEveryWeekHasFourDays() {
        for week in 1...ProgramData.totalWeeks {
            XCTAssertEqual(
                ProgramData.days.filter { $0.week == week }.count,
                ProgramData.daysPerWeek,
                "Week \(week) should have four days"
            )
        }
    }

    func testWeekdaysRunMondayToThursday() {
        for day in ProgramData.days {
            XCTAssertTrue((0...3).contains(day.weekday), "Day \(day.index) falls outside Mon–Thu")
        }
        XCTAssertEqual(ProgramData.days[0].weekdayKey, "weekday.mon")
        XCTAssertEqual(ProgramData.days[3].weekdayKey, "weekday.thu")
        XCTAssertEqual(ProgramData.days[4].weekdayKey, "weekday.mon")
    }

    func testEveryDayHasFourExercises() {
        for day in ProgramData.days {
            XCTAssertEqual(day.exercises.count, 4, "Day \(day.index) should have four exercises")
        }
    }

    func testEveryExerciseExistsInTheCatalog() {
        let catalogIDs = Set(ExerciseCatalog.all.map(\.id))
        let referenced = ProgramData.days.flatMap(\.exercises)
            + ProgramData.warmup
            + ProgramData.cooldown.map(\.ref)
        for ref in referenced {
            XCTAssertTrue(catalogIDs.contains(ref.exercise), "\(ref.exercise.rawValue) is missing from the catalog")
        }
    }

    func testWeekParametersMatchTheProgression() {
        let expected: [Int: (work: Int, rest: Int, rounds: Int)] = [
            1: (40, 20, 3), 2: (40, 20, 3),
            3: (45, 15, 3), 4: (45, 15, 3),
            5: (45, 15, 4), 6: (45, 15, 4),
            7: (50, 10, 4)
        ]
        for (week, values) in expected {
            let params = ProgramData.params(forWeek: week)
            XCTAssertEqual(params.work, values.work, "Week \(week) work time")
            XCTAssertEqual(params.rest, values.rest, "Week \(week) rest time")
            XCTAssertEqual(params.rounds, values.rounds, "Week \(week) rounds")
        }
    }

    func testPhasesFollowTheSpecifiedBlocks() {
        XCTAssertEqual(ProgramData.params(forWeek: 1).phaseKey, "phase.foundation")
        XCTAssertEqual(ProgramData.params(forWeek: 3).phaseKey, "phase.firming")
        XCTAssertEqual(ProgramData.params(forWeek: 5).phaseKey, "phase.endurance")
        XCTAssertEqual(ProgramData.params(forWeek: 7).phaseKey, "phase.consolidation")
    }

    func testWarmupAndCooldownAreFixed() {
        XCTAssertEqual(ProgramData.warmup.count, 4)
        XCTAssertEqual(ProgramData.warmup.count * ProgramData.warmupSeconds, 180)
        XCTAssertEqual(ProgramData.cooldown.reduce(0) { $0 + $1.seconds }, 120)
    }

    func testFinalDayIsTheChallenge() {
        let last = ProgramData.days.first(where: { $0.index == 28 })
        XCTAssertNotNil(last)
        XCTAssertEqual(last?.titleKey, "day.finalChallenge")
        XCTAssertEqual(last?.isFinalDay, true)
        XCTAssertEqual(ProgramData.days.first(where: { $0.index == 27 })?.isFinalDay, false)
    }

    func testOnlyTheIntendedDaysCarryLoad() {
        let weighted = ProgramData.days
            .filter { $0.exercises.contains { $0.modifiers.contains(.weighted) } }
            .map(\.index)
        XCTAssertEqual(weighted, [13, 17, 24, 25, 28])
    }

    func testNextMondayIsAlwaysAMondayInTheFuture() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Lisbon")!
        for offset in 0..<14 {
            let reference = calendar.date(byAdding: .day, value: offset, to: Date())!
            let monday = ProgramState.nextMonday(after: reference, calendar: calendar)
            XCTAssertEqual(calendar.component(.weekday, from: monday), 2)
            XCTAssertGreaterThan(monday, calendar.startOfDay(for: reference))
        }
    }
}
