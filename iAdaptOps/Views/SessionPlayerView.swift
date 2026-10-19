import SwiftUI

struct SessionPlayerView: View {
    let day: ProgramDay
    let viewModel: ProgramViewModel
    /// When set, the completion screen offers a shortcut to the Program tab.
    let onViewProgram: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var player: SessionPlayerViewModel
    @State private var showsExitConfirmation = false
    @State private var showsRestCard = false

    let theme = Theme.shared

    init(day: ProgramDay, lowEnergy: Bool, viewModel: ProgramViewModel, onViewProgram: (() -> Void)? = nil) {
        self.day = day
        self.viewModel = viewModel
        self.onViewProgram = onViewProgram
        _player = State(initialValue: SessionPlayerViewModel(day: day, lowEnergy: lowEnergy))
    }

    var body: some View {
        ZStack {
            background

            if player.isFinished {
                SessionCompleteView(
                    day: day,
                    durationSeconds: player.completedDurationSeconds,
                    daysDone: viewModel.completedCount + (viewModel.isCompleted(day) ? 0 : 1),
                    lowEnergy: player.lowEnergy,
                    offersProgramLink: onViewProgram != nil
                ) { energy, discomfort, note, showProgram in
                    viewModel.complete(
                        day: day,
                        durationSeconds: player.completedDurationSeconds,
                        lowEnergy: player.lowEnergy,
                        energy: energy,
                        discomfort: discomfort,
                        note: note
                    )
                    dismiss()
                    if showProgram { onViewProgram?() }
                }
                .transition(.opacity.combined(with: .scale(scale: 0.96)))
            } else {
                runningSession
            }

            if player.showsSwitchSideBanner {
                switchSideBanner
            }
        }
        .animation(theme.springAnimation, value: player.isFinished)
        .animation(theme.snappyAnimation, value: player.showsSwitchSideBanner)
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
            player.start()
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
            player.stop()
        }
        .sheet(isPresented: $showsRestCard) { stopAndRestSheet }
        .alert(t("session.exitTitle"), isPresented: $showsExitConfirmation) {
            Button(t("action.cancel"), role: .cancel) {}
            Button(t("session.exitConfirm"), role: .destructive) {
                player.stop()
                dismiss()
            }
        } message: {
            Text(t("session.exitBody"))
        }
    }

    // MARK: - Background

    private var background: some View {
        ZStack {
            theme.background
            RadialGradient(
                colors: [accentForPhase.opacity(theme.isDark ? 0.18 : 0.12), .clear],
                center: .top,
                startRadius: 0,
                endRadius: 480
            )
        }
        .ignoresSafeArea()
        .animation(.easeInOut(duration: 0.45), value: player.currentStep.kind)
    }

    private var accentForPhase: Color {
        player.currentStep.isRest ? theme.rest : theme.accent
    }

    // MARK: - Running session

    private var runningSession: some View {
        VStack(spacing: 0) {
            header
            Spacer(minLength: 8)

            ExerciseDemoView(ref: player.displayedRef, lineWidth: 5.5, paceScale: player.lowEnergy ? SessionBuilder.lowEnergyPace : 1)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 130, maxHeight: 200)
                .opacity(player.isPaused ? 0.35 : 1)

            exerciseLabel
                .padding(.top, 6)

            timerRing
                .padding(.top, 14)

            tip
                .padding(.top, 12)
                .padding(.horizontal, 28)

            Spacer(minLength: 8)

            segments
                .padding(.horizontal, 24)
                .padding(.bottom, 14)

            controls
                .padding(.horizontal, 24)
                .padding(.bottom, 10)
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            Button {
                player.pauseIfRunning()
                showsExitConfirmation = true
            } label: {
                Image(systemName: "xmark")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(theme.textDim)
                    .frame(width: 38, height: 38)
                    .background(Circle().fill(theme.panel2))
            }
            .buttonStyle(.plain)

            Spacer()

            VStack(spacing: 3) {
                Text(t(player.currentStep.block.titleKey))
                    .font(.caption.weight(.bold))
                    .textCase(.uppercase)
                    .kerning(0.8)
                    .foregroundStyle(accentForPhase)
                if player.currentStep.block == .workout {
                    Text(t("session.round", player.currentStep.round, player.currentStep.totalRounds))
                        .font(.caption2)
                        .foregroundStyle(theme.textFaint)
                }
            }

            Spacer()

            Button {
                player.pauseIfRunning()
                showsRestCard = true
            } label: {
                Image(systemName: "hand.raised.fill")
                    .font(.subheadline)
                    .foregroundStyle(theme.danger)
                    .frame(width: 38, height: 38)
                    .background(Circle().fill(theme.panel2))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(t("session.stopRest"))
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    private var exerciseLabel: some View {
        VStack(spacing: 7) {
            Text(phaseTitle)
                .font(.title2.bold())
                .multilineTextAlignment(.center)
                .foregroundStyle(theme.text)
                .contentTransition(.opacity)

            if let label = player.displayedRef.modifierLabel, !player.currentStep.isRest {
                ChipView(text: label, icon: "wand.and.stars")
            }
        }
        .padding(.horizontal, 24)
    }

    private var phaseTitle: String {
        switch player.currentStep.kind {
        case .getReady: return t("session.getReady")
        case .rest: return t("session.rest")
        case .work: return t(player.displayedRef.catalogEntry.nameKey)
        }
    }

    private var timerRing: some View {
        ZStack {
            Circle()
                .stroke(theme.panel2, lineWidth: 13)

            Circle()
                .trim(from: 0, to: player.stepProgress)
                .stroke(
                    player.currentStep.isRest
                        ? AnyShapeStyle(theme.restGradient)
                        : AnyShapeStyle(theme.accentGradient),
                    style: StrokeStyle(lineWidth: 13, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: accentForPhase.opacity(0.4), radius: 8)
                .animation(.linear(duration: 0.1), value: player.stepProgress)

            VStack(spacing: 0) {
                Text(player.formattedRemaining)
                    .font(.system(size: 66, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(theme.text)
                if player.isPaused {
                    Text(t("session.paused"))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(theme.textFaint)
                }
            }
        }
        .frame(width: 186, height: 186)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(phaseTitle)
        .accessibilityValue(player.isPaused ? t("session.paused") : "\(player.remaining) s")
    }

    private var tip: some View {
        Group {
            if player.currentStep.isRest || player.currentStep.kind == .getReady {
                HStack(spacing: 10) {
                    Text(t("session.next"))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(theme.textFaint)
                    ExerciseDemoThumbnail(ref: player.displayedRef, size: 38, paceScale: player.lowEnergy ? SessionBuilder.lowEnergyPace : 1)
                    Text(t(player.displayedRef.catalogEntry.nameKey))
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(theme.text)
                        .lineLimit(1)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(Capsule().fill(theme.panel2))
            } else if let cue = workTip {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: cue.icon)
                        .font(.caption)
                        .foregroundStyle(player.lowEnergy ? theme.ok : theme.accent)
                    Text(cue.text)
                        .font(.caption)
                        .multilineTextAlignment(.leading)
                        .foregroundStyle(theme.textDim)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(minHeight: 44)
    }

    /// On a low-energy day the easier version replaces the breathing cue, so
    /// the gentler option is always on screen without having to look it up.
    private var workTip: (icon: String, text: String)? {
        let id = player.displayedRef.catalogEntry.id
        if player.lowEnergy, let easier = tIfPresent(id.easierKey) {
            return ("leaf.fill", easier)
        }
        return tIfPresent(id.breathingKey).map { ("wind", $0) }
    }

    private var segments: some View {
        HStack(spacing: 3) {
            ForEach(player.workStepIndices, id: \.self) { stepIndex in
                Capsule()
                    .fill(
                        stepIndex < player.index
                            ? AnyShapeStyle(theme.accentGradient)
                            : (stepIndex == player.index
                                ? AnyShapeStyle(accentForPhase)
                                : AnyShapeStyle(theme.panel2))
                    )
                    .frame(height: 5)
            }
        }
        .animation(theme.snappyAnimation, value: player.index)
    }

    private var controls: some View {
        HStack(spacing: 16) {
            circleButton("backward.fill", accessibilityKey: "session.previousExercise") {
                player.skipBackward()
            }

            Button {
                player.togglePause()
            } label: {
                Image(systemName: player.isPaused ? "play.fill" : "pause.fill")
                    .font(.title2)
                    .foregroundStyle(theme.onAccent)
                    .frame(width: 74, height: 74)
                    .background(Circle().fill(theme.accentGradient))
                    .shadow(color: theme.accent.opacity(0.4), radius: 14, y: 5)
            }
            .buttonStyle(PressableButtonStyle(scale: 0.94))
            .accessibilityLabel(t(player.isPaused ? "session.resume" : "session.pause"))

            circleButton("forward.fill", accessibilityKey: "session.nextExercise") {
                player.skipForward()
            }
        }
    }

    private func circleButton(_ icon: String, accessibilityKey: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundStyle(theme.textDim)
                .frame(width: 54, height: 54)
                .background(Circle().fill(theme.panel2))
        }
        .buttonStyle(PressableButtonStyle(scale: 0.93))
        .accessibilityLabel(t(accessibilityKey))
    }

    private var switchSideBanner: some View {
        VStack {
            Spacer()
            HStack(spacing: 9) {
                Image(systemName: "arrow.left.arrow.right")
                    .font(.headline)
                Text(t("session.switchSide"))
                    .font(.headline)
            }
            .foregroundStyle(theme.onAccent)
            .padding(.horizontal, 26)
            .padding(.vertical, 15)
            .background(Capsule().fill(theme.accentGradient))
            .shadow(color: theme.accent.opacity(0.45), radius: 18, y: 6)
            .padding(.bottom, 180)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .allowsHitTesting(false)
    }

    // MARK: - Stop and rest

    private var stopAndRestSheet: some View {
        ScrollView {
            VStack(spacing: 16) {
                SafetyCardView(compact: true)

                GradientButton(titleKey: "session.resume", icon: "play.fill") {
                    showsRestCard = false
                    player.togglePause()
                }

                if !player.lowEnergy {
                    OutlineButton(titleKey: "session.switchToLowEnergy", icon: "leaf.fill") {
                        showsRestCard = false
                        player.switchToLowEnergy()
                    }
                }

                Button(role: .destructive) {
                    showsRestCard = false
                    player.stop()
                    dismiss()
                } label: {
                    Text(t("session.exitConfirm"))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(theme.danger)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.plain)
            }
            .padding(20)
        }
        .background(theme.background.ignoresSafeArea())
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
}
