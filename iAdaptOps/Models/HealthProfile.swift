import Foundation

/// A long-term condition the questionnaire asks about. Each one nudges the
/// generated plan: gentler pace, fewer holds, no twisting, and so on.
enum ChronicCondition: String, Codable, CaseIterable, Identifiable {
    case fibromyalgia, chronicFatigue, longCovid, pots
    case inflammatoryArthritis, osteoarthritis, lupus, behcet, hypermobility
    case multipleSclerosis, parkinsons
    case heartCondition, respiratory, diabetes, bowelDisease
    case chronicBackPain, osteoporosis, cancer, postpartum

    var id: String { rawValue }
    var titleKey: String { "condition.\(rawValue)" }
}

/// Something that makes a position or movement hard today, regardless of
/// diagnosis. These rule exercises out rather than just slowing them down.
enum PhysicalLimitation: String, Codable, CaseIterable, Identifiable {
    case kneePain, wristHandPain, shoulderPain, lowBackPain, neckPain
    case dizziness, cannotGetToFloor, cannotStandLong

    var id: String { rawValue }
    var titleKey: String { "limitation.\(rawValue)" }
}

enum ActivityLevel: String, Codable, CaseIterable, Identifiable {
    /// Little or no exercise lately.
    case none
    /// Walks or light activity most weeks.
    case light
    /// Exercise at least twice a week.
    case regular

    var id: String { rawValue }
    var titleKey: String { "activity.\(rawValue)" }
}

/// The answers to the start-up questionnaire. Everything is optional: an
/// empty profile still produces a gentle, safe plan.
struct HealthProfile: Codable, Equatable {
    var age: Int?
    var weightKg: Double?
    var heightCm: Double?
    var conditions: Set<ChronicCondition> = []
    /// Free text for anything not in the list; shown back to the user only.
    var otherConditions: String?
    var limitations: Set<PhysicalLimitation> = []
    /// How much energy a typical day has, 1 (very little) to 5 (plenty).
    var energy: Int = 3
    var activity: ActivityLevel = .none

    static let empty = HealthProfile()

    var bodyMassIndex: Double? {
        guard let weightKg, let heightCm, heightCm > 0 else { return nil }
        let meters = heightCm / 100
        return weightKg / (meters * meters)
    }

    /// Keeps typed values inside sensible human ranges.
    var sanitized: HealthProfile {
        var copy = self
        copy.age = age.flatMap { (10...110).contains($0) ? $0 : nil }
        copy.weightKg = weightKg.flatMap { (25...300).contains($0) ? $0 : nil }
        copy.heightCm = heightCm.flatMap { (100...230).contains($0) ? $0 : nil }
        copy.energy = min(max(energy, 1), 5)
        copy.otherConditions = otherConditions?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .prefix(200)
            .description
        if copy.otherConditions?.isEmpty == true { copy.otherConditions = nil }
        return copy
    }

    // MARK: Storage

    /// Stored as JSON, both in the device's store and in the account's
    /// private cloud document.
    var encoded: String? {
        guard let data = try? JSONEncoder().encode(self) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    init(json: String) throws {
        self = try JSONDecoder().decode(HealthProfile.self, from: Data(json.utf8))
    }

    init(
        age: Int? = nil, weightKg: Double? = nil, heightCm: Double? = nil,
        conditions: Set<ChronicCondition> = [], otherConditions: String? = nil,
        limitations: Set<PhysicalLimitation> = [], energy: Int = 3, activity: ActivityLevel = .none
    ) {
        self.age = age
        self.weightKg = weightKg
        self.heightCm = heightCm
        self.conditions = conditions
        self.otherConditions = otherConditions
        self.limitations = limitations
        self.energy = energy
        self.activity = activity
    }
}
