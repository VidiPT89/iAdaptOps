import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Thin wrapper over UIKit feedback generators so views never touch UIKit
/// directly and every call can be silenced from one place when the user turns
/// haptics off in Settings.
enum Haptics {
    private static let enabledKey = "hapticsEnabled"

    static var isEnabled: Bool {
        get {
            if UserDefaults.standard.object(forKey: enabledKey) == nil { return true }
            return UserDefaults.standard.bool(forKey: enabledKey)
        }
        set { UserDefaults.standard.set(newValue, forKey: enabledKey) }
    }

    @MainActor
    static func selection() {
        #if canImport(UIKit)
        guard isEnabled else { return }
        UISelectionFeedbackGenerator().selectionChanged()
        #endif
    }

    @MainActor
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        #if canImport(UIKit)
        guard isEnabled else { return }
        UIImpactFeedbackGenerator(style: style).impactOccurred()
        #endif
    }

    @MainActor
    static func success() {
        #if canImport(UIKit)
        guard isEnabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        #endif
    }

    @MainActor
    static func warning() {
        #if canImport(UIKit)
        guard isEnabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
        #endif
    }
}
