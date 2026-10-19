import SwiftUI

struct DayDetailView: View {
    let day: ProgramDay
    let viewModel: ProgramViewModel

    @State private var lowEnergy = false
    @State private var seated = false
    @State private var activeDay: ProgramDay?
    @State private var shareText: SharePayload?

    let theme = Theme.shared

    private var params: WeekParams { SessionBuilder.params(for: day, lowEnergy: lowEnergy) }
    /// The day as it would be played with the options chosen here.
    private var shown: ProgramDay { lowEnergy && seated ? day.seatedVersion : day }
    private var isUnlocked: Bool { viewModel.isUnlocked(day) }
    private var isCompleted: Bool { viewModel.isCompleted(day) }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                summary
                block(.warmup, entries: shown.warmup.map { ($0.ref, $0.seconds) })
                block(.workout, entries: workoutEntries)
                block(.cooldown, entries: day.cooldown.map { ($0.ref, $0.seconds) })

                if isUnlocked {
                    GradientButton(
                        titleKey: isCompleted ? "today.repeat" : "today.start",
                        icon: "play.fill"
                    ) {
                        Haptics.impact(.medium)
                        activeDay = shown
                    }
                } else {
                    Text(t("day.locked"))
                        .font(.footnote)
                        .foregroundStyle(theme.textFaint)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 28)
        }
        .scrollIndicators(.hidden)
        .background(theme.background.ignoresSafeArea())
        .navigationTitle("\(t("day.n", day.index))")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    shareText = SharePayload(text: PlanTextExporter.text(for: shown, lowEnergy: lowEnergy))
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
                .tint(theme.accent)
            }
        }
        .onAppear {
            lowEnergy = viewModel.lowEnergyToday
            seated = viewModel.seatedToday
        }
        .fullScreenCover(item: $activeDay) { day in
            SessionPlayerView(day: day, lowEnergy: lowEnergy, viewModel: viewModel)
        }
        .sheet(item: $shareText) { payload in
            ShareSheet(text: payload.text)
        }
    }

    private var workoutEntries: [(ExerciseRef, Int)] {
        let exercises = lowEnergy ? shown.exercises.map(\.softened) : shown.exercises
        return exercises.map { ($0, params.work) }
    }

    // MARK: - Sections

    private var summary: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(t("week.n", day.week)) · \(t(day.weekdayKey))")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(theme.accent)
                    Text(t(day.titleKey))
                        .font(.title2.bold())
                        .foregroundStyle(theme.text)
                }
                Spacer()
                if isCompleted {
                    ChipView(text: t("day.completed"), icon: "checkmark", tint: theme.ok)
                }
            }

            HStack(spacing: 8) {
                ChipView(text: t("params.minutes", SessionBuilder.estimatedMinutes(for: day, lowEnergy: lowEnergy)), icon: "clock.fill")
                ChipView(text: "\(params.work)s / \(params.rest)s", icon: "flame.fill")
                ChipView(text: "\(params.rounds)×", icon: "arrow.triangle.2.circlepath")
                Spacer(minLength: 0)
            }

            Toggle(isOn: $lowEnergy.animation(theme.snappyAnimation)) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(t("lowEnergy.title"))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(theme.text)
                    Text(t("lowEnergy.subtitle"))
                        .font(.caption)
                        .foregroundStyle(theme.textDim)
                }
            }
            .tint(theme.ok)

            if lowEnergy, day.hasSeatedVersion {
                Toggle(isOn: $seated.animation(theme.snappyAnimation)) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(t("seated.title"))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(theme.text)
                        Text(t("seated.subtitle"))
                            .font(.caption)
                            .foregroundStyle(theme.textDim)
                    }
                }
                .tint(theme.ok)
                .transition(.opacity)
            }
        }
        .padding(18)
        .panelBackground()
    }

    private func block(_ kind: BlockKind, entries: [(ExerciseRef, Int)]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(titleKey: kind.titleKey, icon: kind.icon)

            VStack(spacing: 10) {
                ForEach(Array(entries.enumerated()), id: \.offset) { _, entry in
                    HStack(spacing: 13) {
                        ExerciseDemoThumbnail(ref: entry.0, size: 50)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(t(entry.0.catalogEntry.nameKey))
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(theme.text)
                            if let label = entry.0.modifierLabel {
                                Text(label)
                                    .font(.caption)
                                    .foregroundStyle(theme.accent)
                            }
                        }

                        Spacer(minLength: 0)

                        Text("\(entry.1)s")
                            .font(.caption.bold().monospacedDigit())
                            .foregroundStyle(theme.textDim)
                    }
                    .padding(12)
                    .panelBackground()
                }
            }
        }
    }
}
