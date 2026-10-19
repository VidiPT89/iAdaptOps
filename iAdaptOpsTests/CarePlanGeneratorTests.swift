import XCTest
@testable import iAdaptOps

/// The generated care plan must respect every answer of the questionnaire.
final class CarePlanGeneratorTests: XCTestCase {
    private func everyExercise(_ profile: HealthProfile) -> [ExerciseID] {
        CarePlanGenerator.days(for: profile).flatMap { day in
            day.exercises.map(\.exercise) + day.warmup.map(\.ref.exercise) + day.cooldown.map(\.ref.exercise)
        }
    }

    private func info(_ id: ExerciseID) -> ExerciseCareInfo { ExerciseCareInfo.info(id) }

    // MARK: - Shape

    func testEveryProfileGetsTwentyEightCompleteSessions() {
        let profiles: [HealthProfile] = [
            .empty,
            HealthProfile(activity: .regular),
            HealthProfile(conditions: Set(ChronicCondition.allCases), limitations: Set(PhysicalLimitation.allCases), energy: 1),
            HealthProfile(age: 82, limitations: [.cannotGetToFloor, .cannotStandLong])
        ]
        for profile in profiles {
            let days = CarePlanGenerator.days(for: profile)
            XCTAssertEqual(days.map(\.index), Array(1...28))
            for day in days {
                XCTAssertEqual(day.exercises.count, 4, "Day \(day.index)")
                XCTAssertEqual(Set(day.exercises).count, 4, "Day \(day.index) repeats an exercise")
                XCTAssertEqual(day.warmup.count, 4, "Day \(day.index)")
                XCTAssertFalse(day.cooldown.isEmpty)
                XCTAssertNotNil(day.paramsOverride)
                XCTAssertTrue(day.exercises.allSatisfy { $0.modifiers.isEmpty }, "No loads or pulses in care plans")
            }
        }
    }

    func testTheSameAnswersAlwaysGiveTheSamePlan() {
        let profile = HealthProfile(age: 48, conditions: [.fibromyalgia], limitations: [.kneePain], energy: 2, activity: .light)
        XCTAssertEqual(CarePlanGenerator.days(for: profile), CarePlanGenerator.days(for: profile))
    }

    func testSessionsStayShortAndGentle() {
        for profile in [HealthProfile.empty, HealthProfile(energy: 5, activity: .regular)] {
            for day in CarePlanGenerator.days(for: profile) {
                let minutes = SessionBuilder.totalSeconds(for: day) / 60
                XCTAssertLessThanOrEqual(minutes, 20, "Day \(day.index) is too long")
                XCTAssertLessThanOrEqual(day.params.rounds, 3)
                XCTAssertLessThanOrEqual(day.params.work, 45)
            }
        }
    }

    func testProgressionNeverGoesBackwards() {
        let days = CarePlanGenerator.days(for: HealthProfile(activity: .light))
        var previous = 0
        for day in days {
            let effort = day.params.work * day.params.rounds
            XCTAssertGreaterThanOrEqual(effort, previous, "Day \(day.index) is easier than the day before")
            previous = effort
        }
    }

    // MARK: - Tiers

    func testTierFollowsActivityEnergyAgeAndConditions() {
        XCTAssertEqual(CarePlanGenerator.tier(for: .empty), 1)
        XCTAssertEqual(CarePlanGenerator.tier(for: HealthProfile(activity: .regular)), 3)
        XCTAssertEqual(CarePlanGenerator.tier(for: HealthProfile(energy: 2, activity: .regular)), 2)
        XCTAssertEqual(CarePlanGenerator.tier(for: HealthProfile(age: 70, activity: .regular)), 2)
        XCTAssertEqual(CarePlanGenerator.tier(for: HealthProfile(age: 80, activity: .regular)), 1)
        XCTAssertEqual(CarePlanGenerator.tier(for: HealthProfile(conditions: [.heartCondition], activity: .regular)), 2)
        XCTAssertEqual(CarePlanGenerator.tier(for: HealthProfile(conditions: [.chronicFatigue], energy: 5, activity: .regular)), 1)
        XCTAssertEqual(CarePlanGenerator.tier(for: HealthProfile(conditions: [.longCovid], activity: .regular)), 1)
    }

    func testNoExerciseAboveThePlanTier() {
        for activity in ActivityLevel.allCases {
            let profile = HealthProfile(activity: activity)
            let tier = CarePlanGenerator.tier(for: profile)
            for day in CarePlanGenerator.days(for: profile) {
                for ref in day.exercises {
                    XCTAssertLessThanOrEqual(info(ref.exercise).level, tier, "\(ref.exercise) in a tier \(tier) plan")
                }
            }
        }
    }

    // MARK: - Limitations and conditions

    func testNoFloorWorkWhenGettingDownIsHard() {
        let floor: Set<ExerciseCareInfo.Position> = [.floorSupine, .floorSide, .allFours, .kneeling]
        for profile in [
            HealthProfile(limitations: [.cannotGetToFloor], activity: .regular),
            HealthProfile(conditions: [.parkinsons], activity: .regular),
            HealthProfile(weightKg: 130, heightCm: 165, activity: .regular)
        ] {
            XCTAssertTrue(everyExercise(profile).allSatisfy { !floor.contains(info($0).position) })
        }
    }

    func testPainfulJointsAreNotLoaded() {
        let knees = everyExercise(HealthProfile(limitations: [.kneePain], activity: .regular))
        XCTAssertTrue(knees.allSatisfy { !info($0).loads.contains(.knee) })

        let wrists = everyExercise(HealthProfile(limitations: [.wristHandPain], activity: .regular))
        XCTAssertTrue(wrists.allSatisfy { !info($0).loads.contains(.wrist) && info($0).position != .allFours })

        let shoulders = everyExercise(HealthProfile(limitations: [.shoulderPain], activity: .regular))
        XCTAssertTrue(shoulders.allSatisfy { !info($0).loads.contains(.shoulder) })
    }

    func testHeartAndLungConditionsAvoidHeldEfforts() {
        for condition in [ChronicCondition.heartCondition, .respiratory] {
            let plan = everyExercise(HealthProfile(conditions: [condition], activity: .regular))
            XCTAssertFalse(plan.contains(.wallSit))
            XCTAssertTrue(plan.allSatisfy { !info($0).loads.contains(.isometric) })
        }
    }

    func testOsteoporosisAvoidsBendingAndTwisting() {
        let plan = everyExercise(HealthProfile(conditions: [.osteoporosis], activity: .regular))
        XCTAssertTrue(plan.allSatisfy { info($0).loads.isDisjoint(with: [.spinalFlexion, .twist, .deepRange]) })
    }

    func testFatigueConditionsStaySeatedOrLyingDown() {
        for condition in [ChronicCondition.chronicFatigue, .pots] {
            let plan = everyExercise(HealthProfile(conditions: [condition], activity: .regular))
            XCTAssertTrue(plan.allSatisfy {
                ![ExerciseCareInfo.Position.standing, .standingSupported].contains(info($0).position)
            }, "\(condition) plan asks to stand")
        }
    }

    func testBalanceRiskKeepsBothHandsOnTheChair() {
        for profile in [
            HealthProfile(limitations: [.dizziness], activity: .regular),
            HealthProfile(conditions: [.multipleSclerosis], activity: .regular),
            HealthProfile(age: 78, activity: .regular)
        ] {
            for id in everyExercise(profile) where info(id).loads.contains(.balance) {
                XCTAssertEqual(info(id).position, .standingSupported, "\(id) without support")
            }
        }
    }

    func testEverythingRuledOutStillLeavesASafeSeatedPlan() {
        let profile = HealthProfile(
            conditions: Set(ChronicCondition.allCases),
            limitations: Set(PhysicalLimitation.allCases),
            energy: 1
        )
        let plan = everyExercise(profile)
        XCTAssertTrue(plan.allSatisfy { info($0).position == .seated }, "Only seated exercises should remain")
        XCTAssertEqual(CarePlanGenerator.tier(for: profile), 1)
    }

    // MARK: - Profile

    func testProfileSurvivesStorageAndDropsImpossibleValues() throws {
        let profile = HealthProfile(
            age: 52, weightKg: 68.5, heightCm: 164, conditions: [.behcet, .postpartum],
            otherConditions: "  Enxaqueca  ", limitations: [.neckPain], energy: 9, activity: .light
        )
        let json = try XCTUnwrap(profile.encoded)
        XCTAssertEqual(try HealthProfile(json: json), profile)

        let clean = HealthProfile(age: 400, weightKg: 5, heightCm: 999, otherConditions: "   ", energy: 9).sanitized
        XCTAssertNil(clean.age)
        XCTAssertNil(clean.weightKg)
        XCTAssertNil(clean.heightCm)
        XCTAssertNil(clean.otherConditions)
        XCTAssertEqual(clean.energy, 5)
        XCTAssertEqual(profile.sanitized.otherConditions, "Enxaqueca")
    }

    @MainActor
    func testEveryAnswerHasATranslation() {
        for key in ChronicCondition.allCases.map(\.titleKey)
            + PhysicalLimitation.allCases.map(\.titleKey)
            + ActivityLevel.allCases.map(\.titleKey)
            + ["tier.1", "tier.2", "tier.3"] {
            XCTAssertNotNil(tIfPresent(key), key)
        }
        for day in CarePlanGenerator.days(for: .empty) {
            XCTAssertNotNil(tIfPresent(day.titleKey), day.titleKey)
            XCTAssertNotNil(tIfPresent(day.params.phaseKey), day.params.phaseKey)
            XCTAssertNotNil(tIfPresent(day.params.phaseDescriptionKey), day.params.phaseDescriptionKey)
        }
    }
}

extension CarePlanGeneratorTests {
    private var variedProfiles: [HealthProfile] {
        [
            .empty,
            HealthProfile(activity: .regular),
            HealthProfile(age: 58, conditions: [.fibromyalgia, .osteoarthritis], limitations: [.kneePain, .cannotGetToFloor], energy: 2, activity: .light),
            HealthProfile(conditions: [.behcet, .postpartum], energy: 3, activity: .light)
        ]
    }

    func testTheMainBlockDoesNotRepeatTheWarmup() {
        for profile in variedProfiles {
            for day in CarePlanGenerator.days(for: profile) {
                let warmup = Set(day.warmup.map(\.ref.exercise))
                let main = day.exercises.map(\.exercise)
                XCTAssertTrue(main.allSatisfy { !warmup.contains($0) }, "Day \(day.index) repeats its warm-up")
            }
        }
    }

    func testDaysOfTheSameWeekAreNotAllTheSame() {
        for profile in variedProfiles {
            let days = CarePlanGenerator.days(for: profile)
            for week in 1...7 {
                let blocks = days.filter { $0.week == week }.map { Set($0.exercises.map(\.exercise)) }
                XCTAssertGreaterThanOrEqual(Set(blocks).count, 3, "Week \(week) has too many identical days")
            }
        }
    }
}

extension CarePlanGeneratorTests {
    func testMaterialsFollowWhatThePlanUses() {
        let seated = CarePlanGenerator.days(for: HealthProfile(limitations: [.cannotGetToFloor]))
        XCTAssertEqual(Material.needed(for: seated), [.chair])

        let ana = ProgramVariant.anaChallenge.days(profile: nil)
        XCTAssertEqual(Material.needed(for: ana), [.chair, .mat, .bottles, .towel])

        let generated = CarePlanGenerator.days(for: HealthProfile(activity: .regular))
        XCTAssertFalse(Material.needed(for: generated).contains(.bottles), "Care plans never use bottles")
    }

    func testLowEnergyStillEasesTheGentlestPlan() {
        let day = CarePlanGenerator.days(for: .empty)[0]
        XCTAssertEqual(day.params.rounds, 2)
        let eased = SessionBuilder.params(for: day, lowEnergy: true)
        XCTAssertEqual(eased.rounds, 1)
        XCTAssertEqual(eased.work, 15)
        XCTAssertGreaterThan(eased.rest, day.params.rest)
    }

    func testTypedNumbersAcceptTheDecimalComma() {
        XCTAssertEqual(QuestionnaireNumbers.decimal("68,5"), 68.5)
        XCTAssertEqual(QuestionnaireNumbers.decimal("68.5"), 68.5)
        XCTAssertEqual(QuestionnaireNumbers.decimal("68,"), 68)
        XCTAssertNil(QuestionnaireNumbers.decimal(""))
        XCTAssertEqual(QuestionnaireNumbers.integer("4a2"), 42)
        XCTAssertEqual(QuestionnaireNumbers.text(70), "70")
        XCTAssertEqual(QuestionnaireNumbers.text(70.5), "70.5")
    }
}

@MainActor
final class AchievementsForPlanTests: XCTestCase {
    func testFirstLoadOnlyAppearsInPlansWithBottles() throws {
        let personal = ProgramViewModel()
        XCTAssertFalse(personal.achievements.contains(.firstLoad))

        let ana = ProgramViewModel()
        ana.assignedProgramID = ProgramVariant.anaChallenge.rawValue
        XCTAssertTrue(ana.achievements.contains(.firstLoad))
    }
}
