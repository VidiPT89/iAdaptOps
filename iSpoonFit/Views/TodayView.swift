import SwiftUI

struct TodayView: View {
    let viewModel: ProgramViewModel
    var firstName: String?
    var onShowProgram: () -> Void = {}

    @State private var activeDay: ProgramDay?
    @State private var appeared = false
    @State private var showsQuestionnaire = false
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let theme = Theme.shared

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                ScreenHeader(title: greeting, subtitle: formattedToday)
                    .padding(.top, 8)

                progressCard

                if viewModel.needsQuestionnaire {
                    questionnaireCard
                }

                if viewModel.isProgramComplete {
                    completeCard
                } else if viewModel.daysUntilStart > 0 {
                    upcomingCard
                } else if viewModel.hasTrainedToday {
                    doneTodayCard
                } else if viewModel.isRestDayToday {
                    restDayCard
                } else if let day = viewModel.nextDay {
                    workoutCard(day)
                }

                achievementsStrip
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 12)
        }
        .scrollIndicators(.hidden)
        .onAppear {
            withAnimation(theme.springAnimation.delay(0.05)) { appeared = true }
        }
        .sheet(isPresented: $showsQuestionnaire) {
            HealthQuestionnaireSheet(viewModel: viewModel)
        }
        .fullScreenCover(item: $activeDay) { day in
            SessionPlayerView(
                day: day,
                lowEnergy: viewModel.lowEnergyToday,
                viewModel: viewModel,
                onViewProgram: onShowProgram
            )
        }
    }

    // MARK: - Header helpers

    private var greeting: String {
        let key: String
        switch Calendar.current.component(.hour, from: Date()) {
        case 5..<12: key = "greeting.morning"
        case 12..<19: key = "greeting.afternoon"
        default: key = "greeting.evening"
        }
        guard let firstName, !firstName.isEmpty else { return t(key) }
        return "\(t(key)), \(firstName)"
    }

    private var formattedToday: String {
        let formatter = DateFormatter()
        formatter.locale = LocalizationManager.shared.current.locale
        formatter.setLocalizedDateFormatFromTemplate("EEEEdMMMM")
        return formatter.string(from: Date()).capitalizedFirst
    }

    // MARK: - Cards

    /// For accounts created before the questionnaire existed: the plan is
    /// still generated, but only from safe defaults until it is answered.
    private var questionnaireCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "list.clipboard.fill")
                    .font(.title3)
                    .foregroundStyle(theme.accent)
                    .symbolRenderingMode(.hierarchical)
                Text(t("health.todayTitle"))
                    .font(.headline)
                    .foregroundStyle(theme.text)
                Spacer()
            }
            Text(t("health.todayBody"))
                .font(.subheadline)
                .foregroundStyle(theme.textDim)
                .fixedSize(horizontal: false, vertical: true)
            OutlineButton(titleKey: "health.todayAction", icon: "arrow.right") {
                showsQuestionnaire = true
            }
        }
        .padding(18)
        .panelBackground(highlighted: true)
    }

    /// Side by side normally; stacked at the accessibility text sizes, where
    /// the chips would otherwise be squeezed to a letter per line.
    private var progressCard: some View {
        let stacked = dynamicTypeSize.isAccessibilitySize
        let outer = stacked ? AnyLayout(VStackLayout(alignment: .leading, spacing: 14)) : AnyLayout(HStackLayout(spacing: 18))
        let chips = stacked ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8)) : AnyLayout(HStackLayout(spacing: 8))
        return outer {
            ProgressRing(
                progress: viewModel.progress,
                lineWidth: 9,
                centerText: "\(viewModel.completedCount)",
                centerCaption: t("today.ofTotal", ProgramData.totalDays)
            )
            .frame(width: 78, height: 78)

            VStack(alignment: .leading, spacing: 8) {
                Text(t("today.progress"))
                    .font(.headline)
                    .foregroundStyle(theme.text)

                chips {
                    ChipView(text: "\(viewModel.weeksCompleted) \(t("today.weeksDone"))", icon: "calendar")
                    ChipView(text: "\(viewModel.totalMinutes) min", icon: "clock.fill")
                }
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .panelBackground()
    }

    private func workoutCard(_ day: ProgramDay) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("\(t("week.n", day.week)) · \(t("day.n", day.index))")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(theme.accent)
                    Text(t(day.titleKey))
                        .font(.title2.bold())
                        .foregroundStyle(theme.text)
                }
                Spacer()
                ChipView(
                    text: t("params.minutes", SessionBuilder.estimatedMinutes(for: day, lowEnergy: viewModel.lowEnergyToday)),
                    icon: "clock.fill",
                    filled: true
                )
            }

            let focusKeys = viewModel.playable(day).focusKeys
            if !focusKeys.isEmpty {
                HStack(spacing: 8) {
                    ForEach(focusKeys, id: \.self) { key in
                        ChipView(text: t(key))
                    }
                    Spacer(minLength: 0)
                }
            }

            VStack(spacing: 10) {
                ForEach(exercises(for: day)) { ref in
                    HStack(spacing: 12) {
                        ExerciseDemoThumbnail(
                            ref: ref,
                            size: 46,
                            paceScale: viewModel.lowEnergyToday ? SessionBuilder.lowEnergyPace : 1
                        )
                        VStack(alignment: .leading, spacing: 2) {
                            Text(t(ref.catalogEntry.nameKey))
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(theme.text)
                            if let label = ref.modifierLabel {
                                Text(label)
                                    .font(.caption)
                                    .foregroundStyle(theme.accent)
                            }
                        }
                        Spacer(minLength: 0)
                    }
                }
            }

            lowEnergyToggle

            if viewModel.lowEnergyToday, day.hasSeatedVersion {
                seatedToggle
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }

            GradientButton(titleKey: "today.start", icon: "play.fill") {
                Haptics.impact(.medium)
                activeDay = viewModel.playable(day)
            }
        }
        .padding(18)
        .panelBackground(highlighted: true)
    }

    private func exercises(for day: ProgramDay) -> [ExerciseRef] {
        let played = viewModel.playable(day)
        return viewModel.lowEnergyToday ? played.exercises.map(\.softened) : played.exercises
    }

    private var lowEnergyToggle: some View {
        optionToggle(
            icon: "leaf.fill",
            titleKey: "lowEnergy.title",
            subtitleKey: "lowEnergy.subtitle",
            isOn: Binding(
                get: { viewModel.lowEnergyToday },
                set: { viewModel.lowEnergyToday = $0 }
            )
        )
    }

    private var seatedToggle: some View {
        optionToggle(
            icon: "chair.fill",
            titleKey: "seated.title",
            subtitleKey: "seated.subtitle",
            isOn: Binding(
                get: { viewModel.seatedToday },
                set: { viewModel.seatedToday = $0 }
            )
        )
    }

    private func optionToggle(icon: String, titleKey: String, subtitleKey: String, isOn: Binding<Bool>) -> some View {
        Button {
            Haptics.selection()
            withAnimation(theme.snappyAnimation) { isOn.wrappedValue.toggle() }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundStyle(isOn.wrappedValue ? theme.ok : theme.textFaint)
                    .symbolRenderingMode(.hierarchical)
                    .frame(width: 20)

                VStack(alignment: .leading, spacing: 2) {
                    Text(t(titleKey))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(theme.text)
                    Text(t(subtitleKey))
                        .font(.caption)
                        .foregroundStyle(theme.textDim)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 0)

                Toggle("", isOn: isOn.animation(theme.snappyAnimation))
                    .labelsHidden()
                    .tint(theme.ok)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(theme.panel2)
            )
        }
        .buttonStyle(.plain)
    }

    private var restDayCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "moon.stars.fill")
                    .font(.title3)
                    .foregroundStyle(theme.rest)
                    .symbolRenderingMode(.hierarchical)
                Text(t("today.restDay"))
                    .font(.title3.bold())
                    .foregroundStyle(theme.text)
                Spacer()
            }

            Text(t("today.restTip"))
                .font(.subheadline)
                .foregroundStyle(theme.textDim)
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: 10) {
                restSuggestion("figure.walk", "today.restWalk")
                restSuggestion("wind", "today.restBreathing")
                restSuggestion("figure.flexibility", "today.restStretch")
            }

            if let day = viewModel.nextDay {
                nextWorkoutRow(day, countdown: countdownLabel(viewModel.daysUntilNextTrainingDay))
            }
        }
        .padding(18)
        .panelBackground()
    }

    /// Shown once today's session is logged, so the app never nudges towards
    /// a second workout on the same day.
    private var doneTodayCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.title3)
                    .foregroundStyle(theme.ok)
                    .symbolRenderingMode(.hierarchical)
                    .symbolEffect(.bounce, options: .nonRepeating, value: appeared)
                Text(t("today.doneTitle"))
                    .font(.title3.bold())
                    .foregroundStyle(theme.text)
                Spacer()
            }

            Text(t("today.doneBody"))
                .font(.subheadline)
                .foregroundStyle(theme.textDim)
                .fixedSize(horizontal: false, vertical: true)

            if let day = viewModel.nextDay {
                nextWorkoutRow(day, countdown: nil)
            }
        }
        .padding(18)
        .panelBackground()
    }

    /// Before the chosen start date: a preview of Day 1 and the option to
    /// bring the start forward to today.
    private var upcomingCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "calendar.badge.clock")
                    .font(.title3)
                    .foregroundStyle(theme.accent)
                    .symbolRenderingMode(.hierarchical)
                Text(t("today.startsSoon"))
                    .font(.title3.bold())
                    .foregroundStyle(theme.text)
                Spacer()
                ChipView(text: countdownLabel(viewModel.daysUntilStart), icon: "calendar")
            }

            Text(t("today.startsOn", formattedStartDate))
                .font(.subheadline)
                .foregroundStyle(theme.textDim)
                .fixedSize(horizontal: false, vertical: true)

            if let day = viewModel.nextDay {
                nextWorkoutRow(day, countdown: nil)
            }

            OutlineButton(titleKey: "today.startNow", icon: "play.fill") {
                Haptics.selection()
                withAnimation(theme.springAnimation) { viewModel.updateStartDate(Date()) }
            }
        }
        .padding(18)
        .panelBackground()
    }

    private func nextWorkoutRow(_ day: ProgramDay, countdown: String?) -> some View {
        VStack(spacing: 14) {
            Divider().overlay(theme.accent.opacity(0.12))
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("\(t("today.nextWorkout")) · \(t("day.n", day.index))")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(theme.textFaint)
                    Text(t(day.titleKey))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(theme.text)
                }
                Spacer()
                if let countdown {
                    ChipView(text: countdown, icon: "calendar")
                }
            }
        }
    }

    private func countdownLabel(_ days: Int) -> String {
        days <= 1 ? t("today.nextTomorrow") : t("today.nextInDays", days)
    }

    private var formattedStartDate: String {
        guard let start = viewModel.state?.startDate else { return "" }
        let formatter = DateFormatter()
        formatter.locale = LocalizationManager.shared.current.locale
        formatter.setLocalizedDateFormatFromTemplate("EEEEdMMMM")
        return formatter.string(from: start)
    }

    private func restSuggestion(_ icon: String, _ key: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.footnote)
                .foregroundStyle(theme.accent)
                .frame(width: 22)
                .symbolRenderingMode(.hierarchical)
            Text(t(key))
                .font(.subheadline)
                .foregroundStyle(theme.textDim)
            Spacer(minLength: 0)
        }
    }

    private var completeCard: some View {
        VStack(spacing: 14) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 42))
                .foregroundStyle(theme.accentGradient)
                .symbolEffect(.bounce, options: .nonRepeating, value: appeared)

            Text(t("today.programComplete"))
                .font(.title3.bold())
                .foregroundStyle(theme.text)

            Text(t("today.programCompleteBody"))
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(theme.textDim)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .panelBackground(highlighted: true)
    }

    private var achievementsStrip: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(titleKey: "achievements.title", icon: "rosette")

            ScrollView(.horizontal) {
                HStack(spacing: 10) {
                    ForEach(viewModel.achievements) { achievement in
                        let unlocked = viewModel.isUnlocked(achievement)
                        VStack(spacing: 7) {
                            Image(systemName: achievement.icon)
                                .font(.title3)
                                .foregroundStyle(unlocked ? AnyShapeStyle(theme.accentGradient) : AnyShapeStyle(theme.textFaint))
                                .symbolRenderingMode(.hierarchical)
                            Text(t(achievement.titleKey))
                                .font(.caption2)
                                .multilineTextAlignment(.center)
                                .foregroundStyle(unlocked ? theme.text : theme.textFaint)
                        }
                        .frame(width: 96, height: 82)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(theme.panel)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .strokeBorder(
                                    unlocked ? theme.accent.opacity(0.35) : theme.accent.opacity(0.08),
                                    lineWidth: 1
                                )
                        )
                        .opacity(unlocked ? 1 : 0.55)
                    }
                }
            }
            .scrollIndicators(.hidden)
        }
    }
}

extension String {
    var capitalizedFirst: String {
        guard let first else { return self }
        return String(first).uppercased() + dropFirst()
    }
}
