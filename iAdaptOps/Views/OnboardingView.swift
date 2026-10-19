import SwiftUI

struct OnboardingView: View {
    let viewModel: ProgramViewModel

    @State private var page = 0
    @State private var clearance = false
    @State private var startDate = ProgramState.nextMonday()
    @State private var reminderEnabled = false
    @State private var reminderTime = Calendar.current.date(
        from: DateComponents(hour: 9, minute: 0)
    ) ?? Date()
    @State private var healthProfile = HealthProfile.empty

    let theme = Theme.shared

    private enum Page { case welcome, safety, health, material, start }

    /// A fixed plan (assigned by the admin) does not need the questionnaire.
    private var pages: [Page] {
        viewModel.variant.isFixed
            ? [.welcome, .safety, .material, .start]
            : [.welcome, .safety, .health, .material, .start]
    }

    private var pageCount: Int { pages.count }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                LanguagePill()
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)

            TabView(selection: $page) {
                ForEach(Array(pages.enumerated()), id: \.offset) { index, kind in
                    pageView(kind).tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            // Swiping must not get past the safety page without the clearance
            // confirmation, just like the Next button.
            .onChange(of: page) { _, newValue in
                if newValue > 1 && !clearance {
                    withAnimation(theme.springAnimation) { page = 1 }
                }
            }

            pageDots
                .padding(.vertical, 16)

            footer
                .padding(.horizontal, 20)
                .padding(.bottom, 18)
        }
        .background {
            ZStack {
                theme.background
                theme.backgroundWash
            }
            .ignoresSafeArea()
        }
    }

    // MARK: - Pages

    @ViewBuilder
    private func pageView(_ kind: Page) -> some View {
        switch kind {
        case .welcome: welcomePage
        case .safety: safetyPage
        case .health: healthPage
        case .material: materialPage
        case .start: startPage
        }
    }

    private var healthPage: some View {
        ScrollView {
            VStack(spacing: 18) {
                Image(systemName: "list.clipboard.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(theme.accentGradient)
                    .padding(.top, 20)
                Text(t("health.title"))
                    .font(.title.bold())
                    .foregroundStyle(theme.text)
                HealthQuestionnaireForm(profile: $healthProfile)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 12)
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
    }

    private var welcomePage: some View {
        page(icon: "figure.core.training", titleKey: "onboarding.welcomeTitle") {
            Text(t("onboarding.welcomeBody"))
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(theme.textDim)

            HStack(spacing: 10) {
                highlight("28", t("onboarding.workouts"))
                highlight("10–20", "min")
                highlight("4", t("weekday.mon") + "–" + t("weekday.thu"))
            }
            .padding(.top, 6)
        }
    }

    private var safetyPage: some View {
        page(icon: "heart.text.square.fill", titleKey: "onboarding.safetyTitle") {
            ScrollView {
                SafetyCardView(compact: true)
            }
            .scrollIndicators(.hidden)
            .frame(maxHeight: 340)

            Toggle(isOn: $clearance.animation(theme.snappyAnimation)) {
                Text(t("onboarding.clearance"))
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(theme.text)
            }
            .tint(theme.ok)
            .padding(14)
            .panelBackground(elevated: true)
        }
    }

    private var materialPage: some View {
        page(icon: "shippingbox.fill", titleKey: "onboarding.materialTitle") {
            Text(t("onboarding.materialBody"))
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(theme.textDim)

            VStack(spacing: 10) {
                ForEach(Material.needed(for: plannedDays)) { item in
                    material(item.icon, item.titleKey)
                }
            }
        }
    }

    /// The plan these answers will produce, for the material list.
    private var plannedDays: [ProgramDay] {
        viewModel.variant.isFixed ? viewModel.planDays : CarePlanGenerator.days(for: healthProfile)
    }

    private var startPage: some View {
        page(icon: "calendar.badge.clock", titleKey: "onboarding.startTitle") {
            Text(t("onboarding.startBody"))
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(theme.textDim)

            VStack(spacing: 14) {
                DatePicker(
                    t("settings.startDate"),
                    selection: $startDate,
                    displayedComponents: .date
                )
                .datePickerStyle(.compact)
                .tint(theme.accent)

                Divider().overlay(theme.accent.opacity(0.12))

                Toggle(isOn: $reminderEnabled.animation(theme.snappyAnimation)) {
                    Text(t("onboarding.reminderToggle"))
                        .font(.subheadline.weight(.medium))
                }
                .tint(theme.accent)

                if reminderEnabled {
                    DatePicker(
                        t("settings.reminderTime"),
                        selection: $reminderTime,
                        displayedComponents: .hourAndMinute
                    )
                    .datePickerStyle(.compact)
                    .tint(theme.accent)
                }
            }
            .font(.subheadline)
            .foregroundStyle(theme.text)
            .padding(16)
            .panelBackground(elevated: true)
        }
    }

    // MARK: - Building blocks

    private func page<Content: View>(
        icon: String,
        titleKey: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        ScrollView {
            VStack(spacing: 18) {
                Image(systemName: icon)
                    .font(.system(size: 44))
                    .foregroundStyle(theme.accentGradient)
                    .padding(.top, 20)

                Text(t(titleKey))
                    .font(.title.bold())
                    .multilineTextAlignment(.center)
                    .foregroundStyle(theme.text)

                content()
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 12)
        }
        .scrollIndicators(.hidden)
    }

    private func highlight(_ value: String, _ label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.bold().monospacedDigit())
                .foregroundStyle(theme.accentGradient)
            Text(label)
                .font(.caption2)
                .multilineTextAlignment(.center)
                .foregroundStyle(theme.textDim)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(theme.panel)
        )
    }

    private func material(_ icon: String, _ key: String) -> some View {
        HStack(spacing: 13) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(theme.accent)
                .frame(width: 26)
                .symbolRenderingMode(.hierarchical)
            Text(t(key))
                .font(.subheadline)
                .foregroundStyle(theme.text)
            Spacer(minLength: 0)
        }
        .padding(14)
        .panelBackground()
    }

    private var pageDots: some View {
        HStack(spacing: 7) {
            ForEach(0..<pageCount, id: \.self) { index in
                Capsule()
                    .fill(index == page ? AnyShapeStyle(theme.accentGradient) : AnyShapeStyle(theme.panel2))
                    .frame(width: index == page ? 22 : 7, height: 7)
                    .animation(theme.snappyAnimation, value: page)
            }
        }
    }

    private var footer: some View {
        HStack(spacing: 12) {
            if page > 0 {
                OutlineButton(titleKey: "action.back", icon: "chevron.left") {
                    withAnimation(theme.springAnimation) { page -= 1 }
                }
                .frame(maxWidth: 130)
            }

            if page < pageCount - 1 {
                GradientButton(
                    titleKey: "action.next",
                    icon: "chevron.right",
                    isEnabled: page != 1 || clearance
                ) {
                    withAnimation(theme.springAnimation) { page += 1 }
                }
            } else {
                GradientButton(titleKey: "onboarding.start", icon: "sparkles", isEnabled: clearance) {
                    Haptics.success()
                    viewModel.startProgram(
                        startDate: Calendar.current.startOfDay(for: startDate),
                        reminderTime: reminderEnabled ? reminderTime : nil,
                        medicalClearance: clearance,
                        healthProfile: viewModel.variant.isFixed ? nil : healthProfile
                    )
                }
            }
        }
    }
}
