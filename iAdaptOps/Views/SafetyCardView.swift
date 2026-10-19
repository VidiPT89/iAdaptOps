import SwiftUI

/// The safety points, shown during onboarding, from Settings, and from the
/// "stop and rest" button inside a session.
struct SafetyCardView: View {
    var compact: Bool = false

    let theme = Theme.shared

    private let pointKeys = [
        "safety.point1", "safety.point2", "safety.point3",
        "safety.point4", "safety.point5", "safety.point6"
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 9) {
                Image(systemName: "heart.text.square.fill")
                    .font(.title3)
                    .foregroundStyle(theme.danger)
                    .symbolRenderingMode(.hierarchical)
                Text(t("safety.title"))
                    .font(.headline)
                    .foregroundStyle(theme.text)
                Spacer(minLength: 0)
            }

            VStack(alignment: .leading, spacing: 11) {
                ForEach(pointKeys, id: \.self) { key in
                    HStack(alignment: .top, spacing: 10) {
                        Circle()
                            .fill(theme.accent)
                            .frame(width: 5, height: 5)
                            .padding(.top, 7)
                        Text(t(key))
                            .font(compact ? .caption : .subheadline)
                            .foregroundStyle(theme.textDim)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 0)
                    }
                }
            }
        }
        .padding(18)
        .panelBackground()
    }
}

/// Sheet wrapper used wherever the safety card is presented on its own.
struct SafetySheet: View {
    @Environment(\.dismiss) private var dismiss
    let theme = Theme.shared

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                SafetyCardView()
                OutlineButton(titleKey: "action.understood", icon: "checkmark") {
                    dismiss()
                }
            }
            .padding(20)
        }
        .background(theme.background.ignoresSafeArea())
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
}
