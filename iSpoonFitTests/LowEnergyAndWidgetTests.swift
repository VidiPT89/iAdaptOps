import XCTest
@testable import iSpoonFit

final class SeatedVersionTests: XCTestCase {
    private var allDays: [ProgramDay] {
        ProgramData.days + CarePlanGenerator.days(for: .empty)
    }

    func testEveryWarmupMoveAndExerciseBecomesSeated() {
        for day in allDays {
            let seated = day.seatedVersion
            let moves = seated.warmup.map(\.ref.exercise) + seated.exercises.map(\.exercise)
            for id in moves {
                XCTAssertEqual(ExerciseCareInfo.info(id).position, .seated, "Day \(day.index): \(id)")
            }
        }
    }

    func testSeatedVersionKeepsTheShapeOfTheSession() {
        for day in allDays {
            let seated = day.seatedVersion
            XCTAssertEqual(seated.index, day.index)
            XCTAssertEqual(seated.exercises.count, day.exercises.count)
            XCTAssertEqual(seated.warmup.map(\.seconds), day.warmup.map(\.seconds))
            XCTAssertEqual(seated.cooldown, day.cooldown, "The stretches are kept")
            XCTAssertEqual(SessionBuilder.totalSeconds(for: seated), SessionBuilder.totalSeconds(for: day))
        }
    }

    func testNoMoveRepeatsWithinABlock() {
        for day in allDays {
            let seated = day.seatedVersion
            XCTAssertEqual(Set(seated.exercises.map(\.exercise)).count, seated.exercises.count, "Day \(day.index)")
            XCTAssertEqual(Set(seated.warmup.map(\.ref.exercise)).count, seated.warmup.count, "Day \(day.index)")
        }
    }

    func testLegWorkTurnsIntoSeatedLegWork() {
        let squatDay = ProgramDay(index: 1, titleKey: "day.fullBody", exercises: [ExerciseRef(.sumoSquat, modifiers: [.weighted])])
        XCTAssertEqual(squatDay.seatedVersion.exercises, [ExerciseRef(.seatedKneeExtension)])
    }

    func testAnAlreadySeatedDayOffersNoSeatedVersion() {
        var day = ProgramDay(index: 1, titleKey: "day.care.mobility", exercises: [ExerciseRef(.seatedMarch), ExerciseRef(.shoulderRolls)])
        day.warmup = [TimedStep(ref: ExerciseRef(.diaphragmaticBreathing), seconds: 30)]
        XCTAssertFalse(day.hasSeatedVersion)
        XCTAssertTrue(ProgramData.days[0].hasSeatedVersion)
    }
}

final class WidgetSnapshotTests: XCTestCase {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Lisbon")!
        return calendar
    }()

    /// Monday 19 October 2026, mid-morning.
    private var monday: Date {
        calendar.date(from: DateComponents(year: 2026, month: 10, day: 19, hour: 10))!
    }

    private func date(daysAfterMonday days: Int) -> Date {
        calendar.date(byAdding: .day, value: days, to: monday)!
    }

    private func snapshot(completed: Int = 3, start: Date? = nil, last: Date? = nil) -> WidgetSnapshot {
        WidgetSnapshot(
            language: "pt",
            completed: completed,
            total: 28,
            startDate: start ?? date(daysAfterMonday: -7),
            lastWorkoutDate: last,
            next: completed >= 28 ? nil : .init(dayIndex: completed + 1, week: 1, title: "Treino", minutes: 12)
        )
    }

    func testTrainingDayShowsTheWorkout() {
        XCTAssertEqual(snapshot().status(at: monday, calendar: calendar), .workout)
    }

    func testFridayToSundayAreRestDays() {
        for offset in 4...6 {
            XCTAssertEqual(snapshot().status(at: date(daysAfterMonday: offset), calendar: calendar), .restDay)
        }
    }

    func testAWorkoutLoggedTodayMarksTheDayDone() {
        let done = snapshot(last: monday.addingTimeInterval(-3600))
        XCTAssertEqual(done.status(at: monday, calendar: calendar), .doneToday)
        XCTAssertEqual(done.status(at: date(daysAfterMonday: 1), calendar: calendar), .workout)
    }

    func testAFutureStartCountsDown() {
        let upcoming = snapshot(completed: 0, start: date(daysAfterMonday: 3))
        XCTAssertEqual(upcoming.status(at: monday, calendar: calendar), .startsIn(days: 3))
    }

    func testAFinishedProgramIsComplete() {
        XCTAssertEqual(snapshot(completed: 28).status(at: monday, calendar: calendar), .complete)
    }

    func testNoStartDateMeansNoProgramYet() {
        var empty = snapshot(completed: 0)
        empty.startDate = nil
        XCTAssertEqual(empty.status(at: monday, calendar: calendar), .noProgram)
    }

    func testWidgetTextsExistInBothLanguagesWithoutEmDashes() {
        let keys = ["workout", "restDay", "doneToday", "complete", "startsTomorrow", "startsIn",
                    "upNext", "day", "week", "noProgram", "sessions", "description"]
        for key in keys {
            let pt = WidgetText.text(key, "pt")
            let en = WidgetText.text(key, "en")
            // Unknown keys fall back to the key, and no Portuguese text is
            // spelled like its English key.
            XCTAssertNotEqual(pt, key, key)
            XCTAssertNotEqual(pt, en, key)
            XCTAssertFalse(pt.contains("—") || en.contains("—"), key)
        }
        XCTAssertEqual(WidgetText.text("day", "pt", 13), "Dia 13")
    }
}
