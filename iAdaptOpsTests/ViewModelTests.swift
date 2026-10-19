import SwiftData
import XCTest
@testable import iAdaptOps

@MainActor
final class ViewModelTests: XCTestCase {
    private func day(_ index: Int) -> ProgramDay {
        guard let day = ProgramData.days.first(where: { $0.index == index }) else {
            fatalError("Day \(index) should exist")
        }
        return day
    }

    private func makeProgram() throws -> ProgramViewModel {
        let container = try ModelContainer(
            for: ProgramState.self, CompletedSession.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let viewModel = ProgramViewModel()
        viewModel.load(context: ModelContext(container))
        return viewModel
    }

    // MARK: - Session player

    func testSwitchingToLowEnergyInTheWarmupKeepsTheCurrentExercise() {
        let player = SessionPlayerViewModel(day: day(17), lowEnergy: false)
        player.skipForward()
        player.skipForward()
        let before = player.currentStep

        player.switchToLowEnergy()

        XCTAssertTrue(player.lowEnergy)
        XCTAssertEqual(player.currentStep.block, .warmup)
        XCTAssertEqual(player.currentStep.ref, before.ref)
    }

    func testSwitchingToLowEnergyInTheCircuitRestartsAnExistingRound() {
        let player = SessionPlayerViewModel(day: day(17), lowEnergy: false)
        while !(player.currentStep.block == .workout && player.currentStep.round == 4) {
            player.skipForward()
        }

        player.switchToLowEnergy()

        // Week 5 drops from four rounds to three, so round 4 becomes round 3.
        XCTAssertEqual(player.currentStep.block, .workout)
        XCTAssertEqual(player.currentStep.kind, .work)
        XCTAssertEqual(player.currentStep.round, 3)
        XCTAssertEqual(player.currentStep.totalRounds, 3)
        XCTAssertFalse(player.steps.contains { $0.ref.modifiers.contains(.weighted) })
    }

    func testSwitchingToLowEnergyInTheStretchesKeepsTheCurrentStretch() {
        let player = SessionPlayerViewModel(day: day(1), lowEnergy: false)
        while player.currentStep.block != .cooldown {
            player.skipForward()
        }
        player.skipForward()
        let before = player.currentStep

        player.switchToLowEnergy()

        XCTAssertEqual(player.currentStep.block, .cooldown)
        XCTAssertEqual(player.currentStep.ref, before.ref)
    }

    // MARK: - Program calendar

    func testAFutureStartDateIsCountedInWholeDays() throws {
        let viewModel = try makeProgram()
        let start = Calendar.current.date(byAdding: .day, value: 3, to: Date())!
        viewModel.startProgram(startDate: start, reminderTime: nil, medicalClearance: true)

        XCTAssertTrue(viewModel.hasOnboarded)
        XCTAssertEqual(viewModel.daysUntilStart, 3)

        viewModel.updateStartDate(Date())
        XCTAssertEqual(viewModel.daysUntilStart, 0)
    }

    func testFinishingAWorkoutMarksTodayAsTrained() throws {
        let viewModel = try makeProgram()
        viewModel.startProgram(startDate: Date(), reminderTime: nil, medicalClearance: true)
        XCTAssertFalse(viewModel.hasTrainedToday)

        viewModel.complete(day: day(1), durationSeconds: 1_020, lowEnergy: false)

        XCTAssertTrue(viewModel.hasTrainedToday)
        XCTAssertEqual(viewModel.nextDayIndex, 2)
        XCTAssertTrue(viewModel.isUnlocked(Achievement.firstWorkout))
    }
}
