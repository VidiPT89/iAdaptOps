import SwiftUI

struct ExerciseDetailView: View {
    let ref: ExerciseRef

    let theme = Theme.shared

    private var exercise: Exercise { ref.catalogEntry }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                hero
                muscles

                if !ref.modifiers.isEmpty {
                    modifiers
                }

                section("detail.steps", icon: "list.number", text: t(exercise.id.stepsKey))

                if let breathing = tIfPresent(exercise.id.breathingKey) {
                    section("detail.breathing", icon: "wind", text: breathing)
                }
                if let mistake = tIfPresent(exercise.id.mistakeKey) {
                    section("detail.mistake", icon: "exclamationmark.triangle.fill", text: mistake, tint: theme.danger)
                }
                if let easier = tIfPresent(exercise.id.easierKey) {
                    section("detail.easier", icon: "arrow.down.right.circle.fill", text: easier, tint: theme.ok)
                }
                if let caution = tIfPresent(exercise.id.cautionKey) {
                    section("detail.caution", icon: "hand.raised.fill", text: caution, tint: theme.danger)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 28)
        }
        .scrollIndicators(.hidden)
        .background(theme.background.ignoresSafeArea())
        .navigationTitle(t(exercise.nameKey))
        .navigationBarTitleDisplayMode(.inline)
    }

    private var hero: some View {
        VStack(spacing: 14) {
            ExerciseDemoView(ref: ref, lineWidth: 6)
                .frame(height: 210)
                .frame(maxWidth: .infinity)

            Text(t(exercise.nameKey))
                .font(.title2.bold())
                .foregroundStyle(theme.text)
                .multilineTextAlignment(.center)

            HStack(spacing: 8) {
                ChipView(text: t(exercise.category.titleKey), icon: exercise.category.icon)
                if exercise.isUnilateral {
                    ChipView(text: t("session.switchSide"), icon: "arrow.left.arrow.right")
                }
            }
        }
        .padding(18)
        .panelBackground(highlighted: true)
    }

    private var muscles: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(titleKey: "detail.muscles", icon: "figure.strengthtraining.functional")
            HStack(spacing: 8) {
                ForEach(exercise.muscleKeys, id: \.self) { key in
                    ChipView(text: t(key))
                }
                Spacer(minLength: 0)
            }
        }
    }

    private var modifiers: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(ref.modifiers, id: \.self) { modifier in
                HStack(alignment: .top, spacing: 11) {
                    Image(systemName: "wand.and.stars")
                        .font(.footnote)
                        .foregroundStyle(theme.accent)
                        .symbolRenderingMode(.hierarchical)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(t(modifier.labelKey).capitalizedFirst)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(theme.text)
                        Text(t(modifier.descriptionKey))
                            .font(.caption)
                            .foregroundStyle(theme.textDim)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                }
                .padding(14)
                .panelBackground(elevated: true)
            }
        }
    }

    private func section(_ titleKey: String, icon: String, text: String, tint: Color? = nil) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(titleKey: titleKey, icon: icon)
            HStack(alignment: .top, spacing: 11) {
                Rectangle()
                    .fill(tint ?? theme.accent)
                    .frame(width: 3)
                    .clipShape(Capsule())
                Text(text)
                    .font(.subheadline)
                    .foregroundStyle(theme.textDim)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
            .padding(14)
            .panelBackground()
        }
    }
}
