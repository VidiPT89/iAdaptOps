import Foundation

/// Household things a plan needs. Only what the plan actually uses is shown,
/// so nobody goes looking for water bottles a care plan never asks for.
enum Material: String, CaseIterable, Identifiable {
    case chair, mat, bottles, towel

    var id: String { rawValue }
    var titleKey: String { "material.\(rawValue)" }

    var icon: String {
        switch self {
        case .chair: return "chair.fill"
        case .mat: return "square.grid.3x3.fill"
        case .bottles: return "waterbottle.fill"
        case .towel: return "square.stack.3d.up.fill"
        }
    }

    static func needed(for days: [ProgramDay]) -> [Material] {
        let refs = days.flatMap { $0.exercises + $0.warmup.map(\.ref) + $0.cooldown.map(\.ref) }
        let positions = Set(refs.map { ExerciseCareInfo.info($0.exercise).position })
        let onFloor = !positions.isDisjoint(with: [.floorSupine, .floorSide, .allFours, .kneeling])
        return allCases.filter { material in
            switch material {
            case .chair: return true
            case .mat: return onFloor
            case .bottles: return refs.contains { $0.modifiers.contains(.weighted) }
            case .towel: return refs.contains { $0.exercise == .hamstringStretch }
            }
        }
    }
}
