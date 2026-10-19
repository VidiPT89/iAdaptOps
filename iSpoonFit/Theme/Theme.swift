import SwiftUI

enum ThemeMode: String, CaseIterable {
    case light, dark, system

    var labelKey: String {
        switch self {
        case .light: return "theme.light"
        case .dark: return "theme.dark"
        case .system: return "theme.system"
        }
    }

    var icon: String {
        switch self {
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        case .system: return "circle.lefthalf.filled"
        }
    }
}

/// A concrete set of brand colors for one appearance (dark or light).
struct ThemePalette {
    let background: Color
    let panel: Color
    let panel2: Color
    let accent: Color
    let accentLight: Color
    let accentDark: Color
    let text: Color
    let textDim: Color
    let textFaint: Color
    let danger: Color
    let ok: Color
    let rest: Color

    static let dark = ThemePalette(
        background: Color(hex: 0x0a0a0f),
        panel: Color(hex: 0x0d0d18),
        panel2: Color(hex: 0x12121f),
        accent: Color(hex: 0xf99c00),
        accentLight: Color(hex: 0xfcbb00),
        accentDark: Color(hex: 0xdd7400),
        text: Color(hex: 0xe2e8f0),
        textDim: Color(hex: 0x94a3b8),
        textFaint: Color(hex: 0x5b6474),
        danger: Color(hex: 0xef4444),
        ok: Color(hex: 0x22c55e),
        rest: Color(hex: 0x38bdf8)
    )

    // Same ividi.dev orange/burnt-yellow family, deepened where it doubles as
    // text or icon color so it still clears 4.5:1 against the light background.
    static let light = ThemePalette(
        background: Color(hex: 0xf7f4ef),
        panel: Color(hex: 0xffffff),
        panel2: Color(hex: 0xefe9df),
        accent: Color(hex: 0xb8590a),
        accentLight: Color(hex: 0xf99c00),
        accentDark: Color(hex: 0x8f4300),
        text: Color(hex: 0x17140f),
        textDim: Color(hex: 0x5c574f),
        textFaint: Color(hex: 0x8f897e),
        danger: Color(hex: 0xc62828),
        ok: Color(hex: 0x15803d),
        rest: Color(hex: 0x0369a1)
    )
}

/// Live, observable brand theme. Views read `Theme.shared` colors directly;
/// switching `mode` (or the system appearance, when following it) updates
/// every screen automatically since Observation tracks the property reads.
@MainActor
@Observable
final class Theme {
    static let shared = Theme()

    private static let modeKey = "themeMode"

    var mode: ThemeMode {
        didSet { UserDefaults.standard.set(mode.rawValue, forKey: Self.modeKey) }
    }

    /// Updated by RootView from the environment's actual system appearance.
    var systemIsDark: Bool = true

    private init() {
        if let raw = UserDefaults.standard.string(forKey: Self.modeKey), let saved = ThemeMode(rawValue: raw) {
            mode = saved
        } else {
            mode = .system
        }
    }

    var isDark: Bool {
        switch mode {
        case .dark: return true
        case .light: return false
        case .system: return systemIsDark
        }
    }

    var preferredColorScheme: ColorScheme? {
        switch mode {
        case .dark: return .dark
        case .light: return .light
        case .system: return nil
        }
    }

    private var palette: ThemePalette { isDark ? .dark : .light }

    var background: Color { palette.background }
    var panel: Color { palette.panel }
    var panel2: Color { palette.panel2 }
    var accent: Color { palette.accent }
    var accentLight: Color { palette.accentLight }
    var accentDark: Color { palette.accentDark }
    var text: Color { palette.text }
    var textDim: Color { palette.textDim }
    var textFaint: Color { palette.textFaint }
    var danger: Color { palette.danger }
    var ok: Color { palette.ok }
    var rest: Color { palette.rest }

    /// Primary brand gradient: light at the top-leading corner, deep at the
    /// bottom-trailing one, so gradient-filled shapes read as lit from above.
    var accentGradient: LinearGradient {
        LinearGradient(
            colors: [accentLight, accent, accentDark],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var restGradient: LinearGradient {
        LinearGradient(
            colors: [rest.opacity(0.85), rest],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Text color that sits on top of `accentGradient`. Black on both
    /// appearances: the gradient stays bright enough in light mode too.
    var onAccent: Color { .black }

    /// Very soft vertical wash used behind full screens, so the background is
    /// never a flat block of color.
    var backgroundWash: LinearGradient {
        LinearGradient(
            colors: [
                accent.opacity(isDark ? 0.10 : 0.07),
                background.opacity(0),
                background.opacity(0)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    let cornerRadius: CGFloat = 20
    let springAnimation = Animation.spring(response: 0.45, dampingFraction: 0.78)
    let snappyAnimation = Animation.spring(response: 0.3, dampingFraction: 0.72)

    /// Cards float with a soft drop shadow in light mode; in dark mode a
    /// shadow would only muddy the panel, so the border carries the elevation.
    var cardShadowColor: Color { isDark ? .clear : Color.black.opacity(0.06) }
    var cardShadowRadius: CGFloat { isDark ? 0 : 12 }
    var cardShadowOffset: CGFloat { isDark ? 0 : 5 }
}

extension Color {
    init(hex: UInt32, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 8) & 0xff) / 255,
            blue: Double(hex & 0xff) / 255,
            opacity: alpha
        )
    }
}
