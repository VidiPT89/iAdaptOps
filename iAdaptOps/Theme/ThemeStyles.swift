import SwiftUI

struct PanelBackground: ViewModifier {
    var elevated: Bool = false
    var highlighted: Bool = false
    let theme = Theme.shared

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: theme.cornerRadius, style: .continuous)
        content
            .background(elevated ? theme.panel2 : theme.panel)
            .clipShape(shape)
            .overlay(
                shape.strokeBorder(
                    highlighted ? AnyShapeStyle(theme.accentGradient) : AnyShapeStyle(theme.accent.opacity(0.10)),
                    lineWidth: highlighted ? 1.5 : 1
                )
            )
            .shadow(
                color: theme.cardShadowColor,
                radius: theme.cardShadowRadius,
                y: theme.cardShadowOffset
            )
    }
}

extension View {
    func panelBackground(elevated: Bool = false, highlighted: Bool = false) -> some View {
        modifier(PanelBackground(elevated: elevated, highlighted: highlighted))
    }
}

/// Shrinks slightly while held, which makes large tap targets feel physical.
struct PressableButtonStyle: ButtonStyle {
    var scale: CGFloat = 0.97

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

/// The app's primary call to action: gradient fill, warm glow and a press
/// state that dims the glow as the button sinks.
struct GradientButton: View {
    let titleKey: String
    var icon: String? = nil
    var isEnabled: Bool = true
    let action: () -> Void

    let theme = Theme.shared

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if let icon {
                    Image(systemName: icon)
                        .font(.headline)
                        .symbolRenderingMode(.hierarchical)
                }
                Text(t(titleKey))
                    .font(.headline)
            }
            .foregroundStyle(theme.onAccent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 17)
            .background(theme.accentGradient)
            .clipShape(RoundedRectangle(cornerRadius: theme.cornerRadius, style: .continuous))
            .shadow(color: theme.accent.opacity(isEnabled ? 0.35 : 0), radius: 14, y: 6)
            .opacity(isEnabled ? 1 : 0.4)
        }
        .buttonStyle(PressableButtonStyle())
        .disabled(!isEnabled)
    }
}

/// Outlined secondary action, used next to a `GradientButton`.
struct OutlineButton: View {
    let titleKey: String
    var icon: String? = nil
    let action: () -> Void

    let theme = Theme.shared

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon {
                    Image(systemName: icon)
                        .symbolRenderingMode(.hierarchical)
                }
                Text(t(titleKey))
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(theme.accent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(
                RoundedRectangle(cornerRadius: theme.cornerRadius, style: .continuous)
                    .strokeBorder(theme.accent.opacity(0.35), lineWidth: 1.5)
            )
        }
        .buttonStyle(PressableButtonStyle())
    }
}

/// Small rounded label used for focus areas, parameters and modifiers.
struct ChipView: View {
    let text: String
    var icon: String? = nil
    var tint: Color? = nil
    var filled: Bool = false

    let theme = Theme.shared

    private var color: Color { tint ?? theme.accent }

    var body: some View {
        HStack(spacing: 5) {
            if let icon {
                Image(systemName: icon)
                    .font(.caption2.weight(.semibold))
                    .symbolRenderingMode(.hierarchical)
            }
            Text(text)
                .font(.caption.weight(.semibold))
        }
        .foregroundStyle(filled ? theme.onAccent : color)
        .padding(.horizontal, 11)
        .padding(.vertical, 6)
        .background {
            if filled {
                Capsule().fill(theme.accentGradient)
            } else {
                Capsule().fill(color.opacity(0.14))
            }
        }
    }
}

/// Section header with a gradient rule under the title.
struct SectionHeader: View {
    let titleKey: String
    var icon: String? = nil

    let theme = Theme.shared

    var body: some View {
        HStack(spacing: 8) {
            if let icon {
                Image(systemName: icon)
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(theme.accent)
                    .symbolRenderingMode(.hierarchical)
            }
            Text(t(titleKey))
                .font(.footnote.weight(.bold))
                .textCase(.uppercase)
                .kerning(0.8)
                .foregroundStyle(theme.textDim)
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [theme.accent.opacity(0.35), theme.accent.opacity(0)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)
        }
    }
}

/// Circular completion indicator: a track, a gradient trim and a centered
/// label. Used for both overall program progress and per-week progress.
struct ProgressRing: View {
    let progress: Double
    var lineWidth: CGFloat = 10
    var showsPercentage: Bool = true
    var centerText: String? = nil
    var centerCaption: String? = nil

    let theme = Theme.shared

    var body: some View {
        ZStack {
            Circle()
                .stroke(theme.panel2, lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: max(0.001, min(1, progress)))
                .stroke(
                    theme.accentGradient,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: theme.accent.opacity(0.35), radius: 5)
                .animation(theme.springAnimation, value: progress)

            VStack(spacing: 0) {
                if let centerText {
                    Text(centerText)
                        .font(.title3.bold().monospacedDigit())
                        .foregroundStyle(theme.text)
                } else if showsPercentage {
                    Text("\(Int((progress * 100).rounded()))%")
                        .font(.subheadline.bold().monospacedDigit())
                        .foregroundStyle(theme.text)
                }
                if let centerCaption {
                    Text(centerCaption)
                        .font(.caption2)
                        .foregroundStyle(theme.textFaint)
                }
            }
        }
    }
}

/// PT-PT / EN switch shown in every screen's header.
struct LanguagePill: View {
    @State private var lang = LocalizationManager.shared
    let theme = Theme.shared

    var body: some View {
        HStack(spacing: 2) {
            ForEach(Lang.allCases, id: \.self) { option in
                let isSelected = lang.current == option
                Button {
                    Haptics.selection()
                    withAnimation(theme.snappyAnimation) { lang.current = option }
                } label: {
                    Text(option.shortLabel)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(isSelected ? theme.onAccent : theme.textDim)
                        .padding(.horizontal, 11)
                        .padding(.vertical, 6)
                        .background {
                            if isSelected {
                                Capsule()
                                    .fill(theme.accentGradient)
                                    .shadow(color: theme.accent.opacity(0.3), radius: 5)
                            }
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(option.accessibilityName)
                .accessibilityAddTraits(isSelected ? [.isSelected] : [])
            }
        }
        .padding(3)
        .background(Capsule().fill(theme.panel2))
        .overlay(Capsule().strokeBorder(theme.accent.opacity(0.12), lineWidth: 1))
        .accessibilityIdentifier("language.pill")
    }
}

/// Standard screen header: large title on the left, language pill on the right.
struct ScreenHeader<Trailing: View>: View {
    /// Already translated, so a screen can add to it (a name, a date).
    let title: String
    var subtitle: String? = nil
    @ViewBuilder var trailing: Trailing

    let theme = Theme.shared

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.largeTitle.bold())
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                    .foregroundStyle(theme.text)
                if let subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(theme.textDim)
                }
            }
            Spacer()
            trailing
        }
    }
}

extension ScreenHeader where Trailing == LanguagePill {
    init(title: String, subtitle: String? = nil) {
        self.init(title: title, subtitle: subtitle) { LanguagePill() }
    }

    init(titleKey: String, subtitle: String? = nil) {
        self.init(title: t(titleKey), subtitle: subtitle) { LanguagePill() }
    }
}
