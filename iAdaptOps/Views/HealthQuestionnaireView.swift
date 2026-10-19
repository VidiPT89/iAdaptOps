import SwiftUI

/// The health questionnaire as a form: used as a page of the onboarding and,
/// from Settings, to update the answers later. Every question is optional.
struct HealthQuestionnaireForm: View {
    @Binding var profile: HealthProfile

    let theme = Theme.shared

    private let chipColumns = [GridItem(.adaptive(minimum: 150), spacing: 8)]

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(t("health.intro"))
                .font(.subheadline)
                .foregroundStyle(theme.textDim)
                .fixedSize(horizontal: false, vertical: true)

            basics
            conditions
            limitations
            energy
            activity
            preview
        }
    }

    // MARK: - Sections

    private var basics: some View {
        section("health.basics", icon: "person.fill") {
            HStack(spacing: 10) {
                numberField("health.age", value: $profile.age)
                decimalField("health.weight", value: $profile.weightKg)
                decimalField("health.height", value: $profile.heightCm)
            }
        }
    }

    private var conditions: some View {
        section("health.conditions", icon: "cross.case.fill", hint: "health.conditionsHint") {
            LazyVGrid(columns: chipColumns, alignment: .leading, spacing: 8) {
                ForEach(ChronicCondition.allCases) { condition in
                    toggleChip(
                        t(condition.titleKey),
                        isOn: profile.conditions.contains(condition)
                    ) {
                        profile.conditions.formSymmetricDifference([condition])
                    }
                }
            }
            TextField(t("health.other"), text: Binding(
                get: { profile.otherConditions ?? "" },
                set: { profile.otherConditions = String($0.prefix(200)) }
            ))
            .questionnaireField()
        }
    }

    private var limitations: some View {
        section("health.limitations", icon: "hand.raised.fill", hint: "health.limitationsHint") {
            LazyVGrid(columns: chipColumns, alignment: .leading, spacing: 8) {
                ForEach(PhysicalLimitation.allCases) { limitation in
                    toggleChip(
                        t(limitation.titleKey),
                        isOn: profile.limitations.contains(limitation)
                    ) {
                        profile.limitations.formSymmetricDifference([limitation])
                    }
                }
            }
        }
    }

    private var energy: some View {
        section("health.energy", icon: "bolt.fill") {
            HStack(spacing: 6) {
                ForEach(1...5, id: \.self) { value in
                    optionButton("\(value)", isSelected: profile.energy == value) {
                        profile.energy = value
                    }
                }
            }
            HStack {
                Text(t("health.energyLow"))
                Spacer()
                Text(t("health.energyHigh"))
            }
            .font(.caption2)
            .foregroundStyle(theme.textFaint)
        }
    }

    private var activity: some View {
        section("health.activity", icon: "figure.walk") {
            VStack(spacing: 8) {
                ForEach(ActivityLevel.allCases) { level in
                    optionButton(t(level.titleKey), isSelected: profile.activity == level) {
                        profile.activity = level
                    }
                }
            }
        }
    }

    /// What the answers do to the plan, so nothing feels like a black box.
    private var preview: some View {
        let rules = CarePlanGenerator.rules(for: profile)
        var notes: [String] = []
        if rules.excludedPositions.contains(.standing), rules.excludedPositions.contains(.standingSupported) {
            notes.append(t("health.previewNoStanding"))
        }
        if rules.excludedPositions.contains(.floorSupine) {
            notes.append(t("health.previewSeated"))
        }
        if rules.supportedBalanceOnly {
            notes.append(t("health.previewSupported"))
        }
        return VStack(alignment: .leading, spacing: 8) {
            Label(t("health.planPreview"), systemImage: "sparkles")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(theme.accent)
            Text(t("tier.\(rules.tier)"))
                .font(.headline)
                .foregroundStyle(theme.text)
            ForEach(notes, id: \.self) { note in
                Label(note, systemImage: "checkmark")
                    .font(.caption)
                    .foregroundStyle(theme.textDim)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .panelBackground(highlighted: true)
        .animation(theme.snappyAnimation, value: rules)
    }

    // MARK: - Building blocks

    private func section<Content: View>(
        _ titleKey: String,
        icon: String,
        hint: String? = nil,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(titleKey: titleKey, icon: icon)
            if let hint {
                Text(t(hint))
                    .font(.caption)
                    .foregroundStyle(theme.textFaint)
            }
            content()
        }
    }

    private func toggleChip(_ title: String, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.selection()
            withAnimation(theme.snappyAnimation) { action() }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                    .font(.caption)
                Text(title)
                    .font(.caption.weight(.semibold))
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
            .foregroundStyle(isOn ? theme.onAccent : theme.textDim)
            .padding(.horizontal, 11)
            .padding(.vertical, 9)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                if isOn {
                    RoundedRectangle(cornerRadius: 12, style: .continuous).fill(theme.accentGradient)
                } else {
                    RoundedRectangle(cornerRadius: 12, style: .continuous).fill(theme.panel2)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isOn ? [.isSelected] : [])
    }

    private func optionButton(_ title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.selection()
            withAnimation(theme.snappyAnimation) { action() }
        } label: {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isSelected ? theme.onAccent : theme.textDim)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
                .background {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 12, style: .continuous).fill(theme.accentGradient)
                    } else {
                        RoundedRectangle(cornerRadius: 12, style: .continuous).fill(theme.panel2)
                    }
                }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    private func numberField(_ titleKey: String, value: Binding<Int?>) -> some View {
        QuestionnaireNumberField(
            titleKey: titleKey,
            value: Binding(
                get: { value.wrappedValue.map(Double.init) },
                set: { value.wrappedValue = $0.map { Int($0) } }
            ),
            allowsDecimals: false
        )
    }

    private func decimalField(_ titleKey: String, value: Binding<Double?>) -> some View {
        QuestionnaireNumberField(titleKey: titleKey, value: value, allowsDecimals: true)
    }
}

/// A number box that keeps the text exactly as typed (so "68," can become
/// "68,5") and passes the parsed value on at every keystroke, instead of
/// only when the field loses focus as a formatted `TextField(value:)` does.
private struct QuestionnaireNumberField: View {
    let titleKey: String
    @Binding var value: Double?
    let allowsDecimals: Bool

    @State private var text = ""
    let theme = Theme.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(t(titleKey)).font(.caption2).foregroundStyle(theme.textFaint)
            TextField("", text: $text)
                .keyboardType(allowsDecimals ? .decimalPad : .numberPad)
                .questionnaireField()
                .onAppear { text = value.map(QuestionnaireNumbers.text) ?? "" }
                .onChange(of: text) { _, newValue in
                    value = allowsDecimals
                        ? QuestionnaireNumbers.decimal(newValue)
                        : QuestionnaireNumbers.integer(newValue).map(Double.init)
                }
        }
    }
}

/// Reads the numbers typed in the questionnaire, accepting the Portuguese
/// decimal comma as well as a point.
enum QuestionnaireNumbers {
    static func integer(_ text: String) -> Int? {
        Int(text.filter(\.isNumber).prefix(3))
    }

    static func decimal(_ text: String) -> Double? {
        let cleaned = text.replacingOccurrences(of: ",", with: ".")
            .filter { $0.isNumber || $0 == "." }
        return Double(cleaned.prefix(6))
    }

    /// Whole numbers without a trailing ".0".
    static func text(_ value: Double) -> String {
        value.rounded() == value ? String(Int(value)) : String(value)
    }
}

/// The questionnaire on its own, opened from Settings to update the answers.
struct HealthQuestionnaireSheet: View {
    let viewModel: ProgramViewModel

    @Environment(\.dismiss) private var dismiss
    @State private var profile: HealthProfile

    let theme = Theme.shared

    init(viewModel: ProgramViewModel) {
        self.viewModel = viewModel
        _profile = State(initialValue: viewModel.healthProfile ?? .empty)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    HealthQuestionnaireForm(profile: $profile)
                    GradientButton(titleKey: "health.save", icon: "checkmark") {
                        Haptics.success()
                        viewModel.updateHealthProfile(profile)
                        dismiss()
                    }
                }
                .padding(20)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(theme.background.ignoresSafeArea())
            .navigationTitle(t("health.edit"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(t("action.cancel")) { dismiss() }
                        .tint(theme.accent)
                }
            }
        }
    }
}

private extension View {
    func questionnaireField() -> some View {
        let theme = Theme.shared
        return self
            .font(.subheadline)
            .foregroundStyle(theme.text)
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(theme.panel2)
            )
    }
}
