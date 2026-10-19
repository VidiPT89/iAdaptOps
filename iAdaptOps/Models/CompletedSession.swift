import Foundation
import SwiftData

/// One finished workout. Repeating a day adds another row, so the history is
/// a full log rather than a set of flags.
@Model
final class CompletedSession {
    var dayIndex: Int
    var date: Date
    var durationSeconds: Int
    var lowEnergy: Bool
    var energy: Int?
    var discomfort: Int?
    var note: String?
    /// Stable identity across devices, also the cloud document id.
    var uuid: String = UUID().uuidString
    /// True once the cloud has confirmed this row. A synced row that later
    /// goes missing from the cloud was deleted on another device.
    var isSynced: Bool = false

    init(
        uuid: String = UUID().uuidString,
        isSynced: Bool = false,
        dayIndex: Int,
        date: Date = Date(),
        durationSeconds: Int,
        lowEnergy: Bool = false,
        energy: Int? = nil,
        discomfort: Int? = nil,
        note: String? = nil
    ) {
        self.uuid = uuid
        self.isSynced = isSynced
        self.dayIndex = dayIndex
        self.date = date
        self.durationSeconds = durationSeconds
        self.lowEnergy = lowEnergy
        self.energy = energy
        self.discomfort = discomfort
        self.note = note
    }

    var minutes: Int { max(1, Int((Double(durationSeconds) / 60).rounded())) }
}
