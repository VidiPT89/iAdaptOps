import SwiftUI

struct ProgramView: View {
    let viewModel: ProgramViewModel

    @State private var selectedWeek = 1
    @State private var shareText: SharePayload?

    let theme = Theme.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    ScreenHeader(
                        titleKey: "tab.program",
                        subtitle: viewModel.variant.isFixed
                            ? t(viewModel.variant.titleKey)
                            : t("tier.\(CarePlanGenerator.tier(for: viewModel.healthProfile ?? .empty))")
                    )
                        .padding(.top, 8)

                    weekSelector
                    phaseCard
                    daysList
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
            .background(theme.background.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: ProgramDay.self) { day in
                DayDetailView(day: day, viewModel: viewModel)
            }
        }
        .onAppear {
            selectedWeek = viewModel.nextDay?.week ?? ProgramData.totalWeeks
        }
        .sheet(item: $shareText) { payload in
            ShareSheet(text: payload.text)
        }
    }

    // MARK: - Week selector

    private var weekSelector: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 9) {
                ForEach(1...ProgramData.totalWeeks, id: \.self) { week in
                    weekChip(week)
                }
            }
            .padding(.vertical, 2)
        }
        .scrollIndicators(.hidden)
    }

    private func weekChip(_ week: Int) -> some View {
        let isSelected = selectedWeek == week
        let isComplete = viewModel.isWeekComplete(week)
        return Button {
            Haptics.selection()
            withAnimation(theme.snappyAnimation) { selectedWeek = week }
        } label: {
            HStack(spacing: 5) {
                if isComplete {
                    Image(systemName: "checkmark")
                        .font(.caption2.weight(.bold))
                }
                Text(t("week.short", week))
                    .font(.subheadline.weight(.semibold))
            }
            .foregroundStyle(isSelected ? theme.onAccent : (isComplete ? theme.ok : theme.textDim))
            .padding(.horizontal, 15)
            .padding(.vertical, 9)
            .background {
                if isSelected {
                    Capsule().fill(theme.accentGradient)
                        .shadow(color: theme.accent.opacity(0.3), radius: 6, y: 2)
                } else {
                    Capsule().fill(theme.panel2)
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Phase and parameters

    private var params: WeekParams {
        viewModel.days(inWeek: selectedWeek).first?.params ?? ProgramData.params(forWeek: selectedWeek)
    }

    private var phaseCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(t(params.phaseKey))
                        .font(.title3.bold())
                        .foregroundStyle(theme.text)
                    Text(t(params.phaseDescriptionKey))
                        .font(.subheadline)
                        .foregroundStyle(theme.textDim)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 12)
                ProgressRing(
                    progress: Double(viewModel.completedDays(inWeek: selectedWeek)) / Double(ProgramData.daysPerWeek),
                    lineWidth: 7,
                    centerText: "\(viewModel.completedDays(inWeek: selectedWeek))/\(ProgramData.daysPerWeek)"
                )
                .frame(width: 58, height: 58)
            }

            HStack(spacing: 10) {
                paramTile("params.work", "\(params.work)s", "flame.fill")
                paramTile("params.rest", "\(params.rest)s", "pause.fill")
                paramTile("params.rounds", "\(params.rounds)", "arrow.triangle.2.circlepath")
            }

            Button {
                shareText = SharePayload(text: PlanTextExporter.text(forWeek: selectedWeek, days: viewModel.days(inWeek: selectedWeek)))
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "square.and.arrow.up")
                    Text(t("share.weekTitle"))
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(theme.accent)
            }
            .buttonStyle(.plain)
        }
        .padding(18)
        .panelBackground()
    }

    private func paramTile(_ titleKey: String, _ value: String, _ icon: String) -> some View {
        VStack(spacing: 5) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(theme.accent)
                .symbolRenderingMode(.hierarchical)
            Text(value)
                .font(.headline.monospacedDigit())
                .foregroundStyle(theme.text)
            Text(t(titleKey))
                .font(.caption2)
                .foregroundStyle(theme.textFaint)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(theme.panel2)
        )
    }

    // MARK: - Days

    private var daysList: some View {
        VStack(spacing: 12) {
            SectionHeader(titleKey: "program.days", icon: "list.bullet")
            ForEach(viewModel.days(inWeek: selectedWeek)) { day in
                dayRow(day)
            }
        }
    }

    private func dayRow(_ day: ProgramDay) -> some View {
        let isCompleted = viewModel.isCompleted(day)
        let isUnlocked = viewModel.isUnlocked(day)
        let isNext = viewModel.nextDayIndex == day.index

        return NavigationLink(value: day) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(isCompleted ? AnyShapeStyle(theme.accentGradient) : AnyShapeStyle(theme.panel2))
                        .frame(width: 44, height: 44)
                    if isCompleted {
                        Image(systemName: "checkmark")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(theme.onAccent)
                    } else {
                        Text("\(day.index)")
                            .font(.subheadline.bold().monospacedDigit())
                            .foregroundStyle(isUnlocked ? theme.text : theme.textFaint)
                    }
                }

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(t(day.weekdayKey))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(theme.accent)
                        if viewModel.isCompletedOnlyOnLowEnergy(day) {
                            Image(systemName: "leaf.fill")
                                .font(.caption2)
                                .foregroundStyle(theme.ok)
                                .accessibilityLabel(t("lowEnergy.title"))
                        }
                        if isNext {
                            ChipView(text: t("session.next"), filled: true)
                        }
                    }
                    Text(t(day.titleKey))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(isUnlocked ? theme.text : theme.textFaint)
                    Text(day.exercises.map { t($0.catalogEntry.nameKey) }.joined(separator: " · "))
                        .font(.caption)
                        .foregroundStyle(theme.textFaint)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)

                Image(systemName: isUnlocked ? "chevron.right" : "lock.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(theme.textFaint)
            }
            .padding(14)
            .panelBackground(highlighted: isNext)
        }
        .buttonStyle(PressableButtonStyle(scale: 0.985))
    }
}

/// Wrapper so a plain string can drive a `sheet(item:)`.
struct SharePayload: Identifiable {
    let id = UUID()
    let text: String
}

struct ShareSheet: UIViewControllerRepresentable {
    let text: String

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [text], applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
