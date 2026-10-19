import SwiftUI

struct RootView: View {
    @Environment(\.colorScheme) private var systemColorScheme
    @Environment(\.scenePhase) private var scenePhase

    @State private var auth = AuthService()
    @State private var session: UserSession?
    @State private var isSyncing = false
    @State private var showSplash = true

    let theme = Theme.shared

    var body: some View {
        ZStack {
            theme.background.ignoresSafeArea()

            if showSplash {
                SplashView {
                    withAnimation(.easeInOut(duration: 0.45)) { showSplash = false }
                }
                .transition(.opacity)
            } else if auth.user == nil {
                AuthView(auth: auth)
                    .transition(.opacity)
            } else if let session, !isSyncing {
                signedInContent(session)
            } else {
                SyncingView()
                    .transition(.opacity)
            }
        }
        .preferredColorScheme(theme.preferredColorScheme)
        .animation(theme.springAnimation, value: auth.user?.uid)
        .animation(theme.springAnimation, value: isSyncing)
        .animation(theme.springAnimation, value: session?.viewModel.hasOnboarded)
        .onAppear {
            theme.systemIsDark = systemColorScheme == .dark
            #if DEBUG
            if DebugLaunch.isGuest { auth.continueAsGuest() }
            #endif
        }
        .task(id: auth.user?.uid) {
            await openSession(for: auth.user)
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            Task {
                await auth.refreshUser()
                await session?.viewModel.synchronize()
            }
        }
        .onChange(of: LocalizationManager.shared.current) { _, _ in
            session?.viewModel.rescheduleReminderIfNeeded()
        }
        .onChange(of: systemColorScheme) { _, newValue in
            withAnimation(.easeInOut(duration: 0.3)) {
                theme.systemIsDark = newValue == .dark
            }
        }
    }

    @ViewBuilder
    private func signedInContent(_ session: UserSession) -> some View {
        if session.viewModel.hasOnboarded {
            MainTabView(viewModel: session.viewModel, auth: auth) {
                deleteLocalData(for: session)
            }
            .transition(.opacity.combined(with: .scale(scale: 1.02)))
        } else {
            OnboardingView(viewModel: session.viewModel)
                .transition(.asymmetric(
                    insertion: .opacity,
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
        }
    }

    /// Opens the signed-in account's store and brings it up to date with the
    /// cloud before showing anything, so onboarding never flashes for someone
    /// who already has a program on another phone.
    private func openSession(for user: AccountUser?) async {
        guard let user else {
            if session != nil { ProgramViewModel.clearDeviceState() }
            session = nil
            isSyncing = false
            return
        }
        guard session?.uid != user.uid else { return }

        isSyncing = true
        let newSession = UserSession(user: user, syncsToCloud: user != .localGuest)
        await newSession.viewModel.synchronize()
        // Signed out, or switched account, while the sync was running.
        guard !Task.isCancelled else { return }
        #if DEBUG
        if DebugLaunch.isGuest { DebugLaunch.seed(newSession.viewModel) }
        #endif
        newSession.viewModel.rescheduleReminderIfNeeded()
        session = newSession
        isSyncing = false
    }

    private func deleteLocalData(for session: UserSession) {
        ProgramViewModel.clearDeviceState()
        self.session = nil
        UserSession.removeLocalData(uid: session.uid)
    }
}

/// Shown for the second or two it takes to fetch the account's progress.
private struct SyncingView: View {
    let theme = Theme.shared

    var body: some View {
        VStack(spacing: 14) {
            ProgressView()
                .controlSize(.large)
                .tint(theme.accent)
            Text(t("auth.syncing"))
                .font(.subheadline)
                .foregroundStyle(theme.textDim)
        }
    }
}
