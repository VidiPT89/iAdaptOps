import SwiftUI

struct SettingsView: View {
    let viewModel: ProgramViewModel
    let auth: AuthService
    let onAccountDeleted: () -> Void

    @State private var lang = LocalizationManager.shared
    @State private var theme = Theme.shared
    @State private var soundsEnabled = SessionAudio.soundsEnabled
    @State private var voiceEnabled = SessionAudio.voiceEnabled
    @State private var hapticsEnabled = Haptics.isEnabled
    @State private var healthEnabled = HealthWorkouts.isEnabled
    @State private var healthDenied = false
    @State private var reminderEnabled: Bool
    @State private var reminderTime: Date
    @State private var startDate: Date
    @State private var remindersDenied = false
    @State private var reminderWeekdays = ReminderManager.weekdays
    @State private var showsSafety = false
    @State private var showsHistory = false
    @State private var showsQuestionnaire = false
    @State private var showsRestartConfirmation = false

    init(viewModel: ProgramViewModel, auth: AuthService, onAccountDeleted: @escaping () -> Void) {
        self.viewModel = viewModel
        self.auth = auth
        self.onAccountDeleted = onAccountDeleted
        let state = viewModel.state
        _reminderEnabled = State(initialValue: state?.reminderEnabled ?? false)
        _reminderTime = State(initialValue: state?.reminderTime
            ?? Calendar.current.date(from: DateComponents(hour: 9, minute: 0)) ?? Date())
        _startDate = State(initialValue: state?.startDate ?? Date())
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    ScreenHeader(titleKey: "tab.settings")
                        .padding(.top, 8)

                    AccountCard(auth: auth, viewModel: viewModel, onAccountDeleted: onAccountDeleted)
                    languageCard
                    appearanceCard
                    sessionCard
                    remindersCard
                    programCard
                    aboutCard
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
            .background(theme.background.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
        }
        .sheet(isPresented: $showsSafety) { SafetySheet() }
        .sheet(isPresented: $showsHistory) { HistoryView(viewModel: viewModel) }
        .sheet(isPresented: $showsQuestionnaire) { HealthQuestionnaireSheet(viewModel: viewModel) }
        .alert(t("settings.restart"), isPresented: $showsRestartConfirmation) {
            Button(t("action.cancel"), role: .cancel) {}
            Button(t("settings.restart"), role: .destructive) {
                viewModel.restartProgram()
                startDate = viewModel.state?.startDate ?? Date()
            }
        } message: {
            Text(t("settings.restartConfirm"))
        }
    }

    // MARK: - Cards

    private var languageCard: some View {
        card(titleKey: "settings.language", icon: "globe") {
            HStack(spacing: 10) {
                ForEach(Lang.allCases, id: \.self) { option in
                    let isSelected = lang.current == option
                    Button {
                        Haptics.selection()
                        withAnimation(theme.snappyAnimation) { lang.current = option }
                    } label: {
                        Text(option == .pt ? "PT-PT" : "EN")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(isSelected ? theme.onAccent : theme.textDim)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background {
                                if isSelected {
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(theme.accentGradient)
                                } else {
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(theme.panel2)
                                }
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var appearanceCard: some View {
        card(titleKey: "settings.appearance", icon: "paintbrush.fill") {
            HStack(spacing: 10) {
                ForEach(ThemeMode.allCases, id: \.self) { mode in
                    let isSelected = theme.mode == mode
                    Button {
                        Haptics.selection()
                        withAnimation(.easeInOut(duration: 0.3)) { theme.mode = mode }
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: mode.icon)
                                .font(.subheadline)
                                .symbolRenderingMode(.hierarchical)
                            Text(t(mode.labelKey))
                                .font(.caption.weight(.semibold))
                        }
                        .foregroundStyle(isSelected ? theme.onAccent : theme.textDim)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background {
                            if isSelected {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(theme.accentGradient)
                            } else {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(theme.panel2)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var sessionCard: some View {
        card(titleKey: "settings.session", icon: "speaker.wave.2.fill") {
            VStack(spacing: 4) {
                toggleRow("settings.sound", icon: "speaker.wave.2.fill", isOn: $soundsEnabled)
                    .onChange(of: soundsEnabled) { _, value in SessionAudio.soundsEnabled = value }
                toggleRow("settings.voice", icon: "waveform", isOn: $voiceEnabled)
                    .onChange(of: voiceEnabled) { _, value in SessionAudio.voiceEnabled = value }
                toggleRow("settings.haptics", icon: "iphone.radiowaves.left.and.right", isOn: $hapticsEnabled)
                    .onChange(of: hapticsEnabled) { _, value in Haptics.isEnabled = value }

                if HealthWorkouts.isAvailable {
                    toggleRow("settings.health", icon: "heart.fill", isOn: healthBinding)
                    Text(t(healthDenied ? "settings.healthDenied" : "settings.healthNote"))
                        .font(.caption)
                        .foregroundStyle(healthDenied ? theme.danger : theme.textFaint)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    /// Asks Health for permission when switched on, and flips back off with a
    /// hint when it was not granted.
    private var healthBinding: Binding<Bool> {
        Binding(
            get: { healthEnabled },
            set: { value in
                healthEnabled = value
                healthDenied = false
                guard value else {
                    HealthWorkouts.isEnabled = false
                    return
                }
                Task {
                    let granted = await HealthWorkouts.requestAccess()
                    HealthWorkouts.isEnabled = granted
                    if !granted {
                        withAnimation(theme.snappyAnimation) {
                            healthEnabled = false
                            healthDenied = true
                        }
                    }
                }
            }
        )
    }

    private var remindersCard: some View {
        card(titleKey: "settings.reminders", icon: "bell.fill") {
            VStack(spacing: 10) {
                toggleRow("settings.reminders", icon: "bell.badge.fill", isOn: reminderBinding)

                if remindersDenied {
                    Text(t("settings.remindersDenied"))
                        .font(.caption)
                        .foregroundStyle(theme.danger)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if reminderEnabled {
                    DatePicker(
                        t("settings.reminderTime"),
                        selection: Binding(
                            get: { reminderTime },
                            set: { value in
                                reminderTime = value
                                Task { await viewModel.updateReminder(enabled: true, time: value) }
                            }
                        ),
                        displayedComponents: .hourAndMinute
                    )
                    .font(.subheadline)
                    .foregroundStyle(theme.text)
                    .tint(theme.accent)

                    weekdayPicker

                    Text(t("settings.reminderDays"))
                        .font(.caption)
                        .foregroundStyle(theme.textFaint)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    private var weekdayPicker: some View {
        HStack(spacing: 5) {
            ForEach(ReminderManager.weekOrder, id: \.self) { weekday in
                let isOn = reminderWeekdays.contains(weekday)
                Button {
                    // At least one day has to stay selected.
                    guard !(isOn && reminderWeekdays.count == 1) else { return }
                    Haptics.selection()
                    withAnimation(theme.snappyAnimation) {
                        if isOn { reminderWeekdays.remove(weekday) } else { reminderWeekdays.insert(weekday) }
                    }
                    ReminderManager.weekdays = reminderWeekdays
                    Task { await viewModel.updateReminder(enabled: true, time: reminderTime) }
                } label: {
                    Text(t(ReminderManager.weekdayKey(weekday)))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(isOn ? theme.onAccent : theme.textDim)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background {
                            if isOn {
                                RoundedRectangle(cornerRadius: 9, style: .continuous)
                                    .fill(theme.accentGradient)
                            } else {
                                RoundedRectangle(cornerRadius: 9, style: .continuous)
                                    .fill(theme.panel2)
                            }
                        }
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isOn ? [.isSelected] : [])
            }
        }
    }

    /// Writes straight through to the view model, and flips back off with a
    /// hint when iOS has notifications turned off for the app.
    private var reminderBinding: Binding<Bool> {
        Binding(
            get: { reminderEnabled },
            set: { value in
                reminderEnabled = value
                remindersDenied = false
                Task {
                    let granted = await viewModel.updateReminder(enabled: value, time: reminderTime)
                    if value && !granted {
                        withAnimation(theme.snappyAnimation) {
                            reminderEnabled = false
                            remindersDenied = true
                        }
                    }
                }
            }
        )
    }

    private var programCard: some View {
        card(titleKey: "settings.program", icon: "calendar") {
            VStack(spacing: 10) {
                DatePicker(
                    t("settings.startDate"),
                    selection: Binding(
                        get: { startDate },
                        set: { value in
                            startDate = value
                            viewModel.updateStartDate(value)
                        }
                    ),
                    displayedComponents: .date
                )
                .font(.subheadline)
                .foregroundStyle(theme.text)
                .tint(theme.accent)

                if !viewModel.variant.isFixed {
                    actionRow("health.edit", icon: "list.clipboard.fill") { showsQuestionnaire = true }
                }
                actionRow("settings.history", icon: "clock.arrow.circlepath") { showsHistory = true }
                actionRow("settings.safety", icon: "heart.text.square.fill") { showsSafety = true }
                actionRow("settings.restart", icon: "arrow.counterclockwise", tint: theme.danger) {
                    showsRestartConfirmation = true
                }
            }
        }
    }

    private var aboutCard: some View {
        card(titleKey: "settings.about", icon: "info.circle.fill") {
            VStack(spacing: 12) {
                HStack {
                    Text(t("about.version"))
                        .font(.subheadline)
                        .foregroundStyle(theme.textDim)
                    Spacer()
                    Text(appVersion)
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(theme.text)
                }

                Divider().overlay(theme.accent.opacity(0.12))

                HStack(spacing: 5) {
                    Text(t("about.developedBy"))
                        .foregroundStyle(theme.textDim)
                    Text(t("about.authorName"))
                        .fontWeight(.semibold)
                        .foregroundStyle(theme.text)
                    Spacer()
                }
                .font(.subheadline)

                linkRow("about.website", value: "ividi.dev", icon: "globe", url: "https://ividi.dev/")
                linkRow("about.github", value: "@VidiPT89", icon: "chevron.left.forwardslash.chevron.right", url: "https://github.com/VidiPT89/")
            }
        }
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    // MARK: - Building blocks

    private func card<Content: View>(
        titleKey: String,
        icon: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 13) {
            SectionHeader(titleKey: titleKey, icon: icon)
            content()
        }
        .padding(18)
        .panelBackground()
    }

    private func toggleRow(_ titleKey: String, icon: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn.animation(theme.snappyAnimation)) {
            HStack(spacing: 11) {
                Image(systemName: icon)
                    .font(.footnote)
                    .foregroundStyle(theme.accent)
                    .frame(width: 22)
                    .symbolRenderingMode(.hierarchical)
                Text(t(titleKey))
                    .font(.subheadline)
                    .foregroundStyle(theme.text)
            }
        }
        .tint(theme.accent)
    }

    private func actionRow(_ titleKey: String, icon: String, tint: Color? = nil, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 11) {
                Image(systemName: icon)
                    .font(.footnote)
                    .foregroundStyle(tint ?? theme.accent)
                    .frame(width: 22)
                    .symbolRenderingMode(.hierarchical)
                Text(t(titleKey))
                    .font(.subheadline)
                    .foregroundStyle(tint ?? theme.text)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(theme.textFaint)
            }
            .contentShape(Rectangle())
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }

    private func linkRow(_ titleKey: String, value: String, icon: String, url: String) -> some View {
        Link(destination: URL(string: url)!) {
            HStack(spacing: 11) {
                Image(systemName: icon)
                    .font(.footnote)
                    .foregroundStyle(theme.accent)
                    .frame(width: 22)
                    .symbolRenderingMode(.hierarchical)
                Text(t(titleKey))
                    .font(.subheadline)
                    .foregroundStyle(theme.text)
                Spacer()
                Text(value)
                    .font(.subheadline)
                    .foregroundStyle(theme.accent)
                Image(systemName: "arrow.up.right")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(theme.textFaint)
            }
            .contentShape(Rectangle())
            .padding(.vertical, 4)
        }
    }
}
