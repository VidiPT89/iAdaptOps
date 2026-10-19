import XCTest
@testable import iAdaptOps

@MainActor
final class TranslationsTests: XCTestCase {
    private func assertPresent(_ key: String, file: StaticString = #filePath, line: UInt = #line) {
        guard let entry = Translations.table[key] else {
            XCTFail("Missing translation key: \(key)", file: file, line: line)
            return
        }
        for language in Lang.allCases {
            let value = entry[language] ?? ""
            XCTAssertFalse(
                value.trimmingCharacters(in: .whitespaces).isEmpty,
                "Key \(key) has no \(language.rawValue) text",
                file: file,
                line: line
            )
        }
    }

    // MARK: - Table integrity

    func testEveryEntryHasBothLanguages() {
        for key in Translations.table.keys {
            assertPresent(key)
        }
    }

    func testMergingTheTableLosesNothing() {
        let parts = [
            Translations.core,
            Translations.program,
            Translations.exercises,
            Translations.standingCues,
            Translations.floorCues,
            Translations.account,
            Translations.care,
            Translations.health
        ]
        let total = parts.reduce(0) { $0 + $1.count }
        XCTAssertEqual(
            Translations.table.count,
            total,
            "Two translation files define the same key, so one of them is being dropped"
        )
    }

    func testFormatPlaceholdersMatchAcrossLanguages() {
        for (key, entry) in Translations.table {
            let counts = Lang.allCases.map { (entry[$0] ?? "").components(separatedBy: "%").count }
            XCTAssertEqual(
                Set(counts).count,
                1,
                "Key \(key) has a different number of format placeholders in each language"
            )
        }
    }

    func testPortugueseTextUsesEuropeanForms() {
        let brazilianMarkers = [" você", "você ", " pra ", " ônibus", " tela ", " time "]
        for (key, entry) in Translations.table {
            let text = " " + (entry[.pt] ?? "").lowercased() + " "
            for marker in brazilianMarkers {
                XCTAssertFalse(text.contains(marker), "Key \(key) uses a Brazilian form: \(marker)")
            }
        }
    }

    func testNoEmDashesAnywhere() {
        for (key, entry) in Translations.table {
            for language in Lang.allCases {
                XCTAssertFalse((entry[language] ?? "").contains("—"), "Key \(key) contains an em dash")
            }
        }
    }

    // MARK: - Data-driven keys

    func testEveryCatalogExerciseIsFullyDescribed() {
        for exercise in ExerciseCatalog.all {
            assertPresent(exercise.nameKey)
            assertPresent(exercise.id.stepsKey)
            assertPresent(exercise.category.titleKey)
            XCTAssertFalse(exercise.muscleKeys.isEmpty, "\(exercise.id.rawValue) lists no muscles")
            for key in exercise.muscleKeys {
                assertPresent(key)
            }
        }
    }

    func testEveryExerciseExplainsHowToBreathe() {
        for exercise in ExerciseCatalog.all {
            XCTAssertNotNil(
                Translations.table[exercise.id.breathingKey],
                "\(exercise.id.rawValue) has no breathing cue"
            )
        }
    }

    func testEveryExerciseOffersAnEasierVersion() {
        for exercise in ExerciseCatalog.all {
            XCTAssertNotNil(
                Translations.table[exercise.id.easierKey],
                "\(exercise.id.rawValue) has no easier version"
            )
        }
    }

    func testEveryDayAndPhaseHasATitle() {
        for day in ProgramData.days {
            assertPresent(day.titleKey)
            assertPresent(day.weekdayKey)
        }
        for week in 1...ProgramData.totalWeeks {
            let params = ProgramData.params(forWeek: week)
            assertPresent(params.phaseKey)
            assertPresent(params.phaseDescriptionKey)
        }
    }

    func testEveryEnumSurfacedInTheInterfaceIsTranslated() {
        for modifier in Modifier.allCases {
            assertPresent(modifier.labelKey)
            assertPresent(modifier.descriptionKey)
        }
        for block in BlockKind.allCases {
            assertPresent(block.titleKey)
        }
        for category in ExerciseCategory.allCases {
            assertPresent(category.titleKey)
        }
        for achievement in Achievement.allCases {
            assertPresent(achievement.titleKey)
        }
        for mode in ThemeMode.allCases {
            assertPresent(mode.labelKey)
        }
    }

    func testCoreInterfaceKeysExist() {
        let keys = [
            "app.name", "app.tagline", "about.developedBy", "about.authorName",
            "about.version", "about.website", "about.github",
            "tab.today", "tab.program", "tab.exercises", "tab.settings",
            "greeting.morning", "greeting.afternoon", "greeting.evening",
            "today.start", "today.repeat", "today.restDay", "today.restTip",
            "today.nextWorkout", "today.progress", "today.programComplete",
            "lowEnergy.title", "lowEnergy.subtitle",
            "week.n", "day.n", "week.short",
            "params.work", "params.rest", "params.rounds", "params.minutes",
            "session.getReady", "session.rest", "session.next", "session.switchSide",
            "session.round", "session.pause", "session.resume", "session.stopRest",
            "session.done", "session.exitTitle", "session.exitConfirm",
            "checkin.title", "checkin.energy", "checkin.discomfort",
            "material.mat", "material.chair", "material.bottles", "material.towel",
            "settings.language", "settings.appearance", "settings.sound",
            "settings.voice", "settings.haptics", "settings.reminders",
            "settings.restart", "settings.safety", "settings.about",
            "onboarding.clearance", "onboarding.start", "onboarding.workouts",
            "safety.point1", "safety.point6",
            "history.title", "history.empty", "reminder.title", "reminder.body",
            "action.cancel", "action.done", "action.close"
        ]
        for key in keys {
            assertPresent(key)
        }
    }

    // MARK: - Language switching

    func testLookupFollowsTheSelectedLanguage() {
        let manager = LocalizationManager.shared
        let original = manager.current
        defer { manager.current = original }

        manager.current = .pt
        XCTAssertEqual(manager.t("tab.settings"), "Definições")
        manager.current = .en
        XCTAssertEqual(manager.t("tab.settings"), "Settings")
    }

    func testUnknownKeysFallBackToTheKeyItself() {
        XCTAssertEqual(t("this.key.does.not.exist"), "this.key.does.not.exist")
        XCTAssertNil(tIfPresent("this.key.does.not.exist"))
        XCTAssertNotNil(tIfPresent("app.name"))
    }

    func testParameterisedKeysFormatCorrectly() {
        let manager = LocalizationManager.shared
        let original = manager.current
        defer { manager.current = original }

        manager.current = .pt
        XCTAssertEqual(t("week.n", 3), "Semana 3")
        XCTAssertEqual(t("session.round", 2, 4), "Volta 2 de 4")
        manager.current = .en
        XCTAssertEqual(t("week.n", 3), "Week 3")
        XCTAssertEqual(t("session.round", 2, 4), "Round 2 of 4")
    }

    func testDisplayNameCombinesTheExerciseWithItsModifiers() {
        let manager = LocalizationManager.shared
        let original = manager.current
        defer { manager.current = original }

        manager.current = .pt
        let ref = ExerciseRef(.sumoSquat, modifiers: [.weighted])
        XCTAssertEqual(ref.displayName, "Agachamento sumo · com garrafas")
        XCTAssertEqual(ExerciseRef(.sumoSquat).displayName, "Agachamento sumo")
        XCTAssertNil(ExerciseRef(.sumoSquat).modifierLabel)
    }

    func testSharedPlanTextIsReadableInBothLanguages() {
        let manager = LocalizationManager.shared
        let original = manager.current
        defer { manager.current = original }

        guard let day = ProgramData.days.first(where: { $0.index == 13 }) else { return XCTFail("Day 13 should exist") }
        for language in Lang.allCases {
            manager.current = language
            let text = PlanTextExporter.text(for: day)
            XCTAssertTrue(text.contains("iAdaptOps"))
            XCTAssertTrue(text.contains(t("block.warmup")))
            XCTAssertTrue(text.contains(t("block.cooldown")))
            XCTAssertFalse(text.contains("exercise."), "Untranslated key leaked into the shared text")
            XCTAssertFalse(text.contains("day."), "Untranslated key leaked into the shared text")
            XCTAssertFalse(text.contains("—"), "The shared text should not use em dashes")
        }
    }
}
