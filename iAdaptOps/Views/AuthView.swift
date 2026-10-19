import SwiftUI

/// Sign in or create an account, with email and password or in one tap with
/// Apple, Google or Microsoft.
struct AuthView: View {
    let auth: AuthService

    private enum Mode: Hashable { case signIn, signUp }
    private enum Field: Hashable { case name, email, password }

    @State private var mode: Mode = .signIn
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var showsPassword = false
    @State private var formErrorKey: String?
    @FocusState private var focus: Field?

    let theme = Theme.shared

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                HStack {
                    Spacer()
                    LanguagePill()
                }

                brand

                if auth.phase == .unavailable {
                    unavailableCard
                } else {
                    form
                    divider
                    providerButtons
                    privacyNote
                }
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 12)
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .background {
            ZStack {
                theme.background
                theme.backgroundWash
            }
            .ignoresSafeArea()
        }
        .disabled(auth.isWorking)
        .overlay {
            if auth.isWorking {
                ProgressView()
                    .controlSize(.large)
                    .tint(theme.accent)
                    .padding(24)
                    .background(RoundedRectangle(cornerRadius: 18).fill(theme.panel))
            }
        }
    }

    // MARK: - Brand

    private var brand: some View {
        VStack(spacing: 10) {
            Image("BrandMark")
                .resizable()
                .scaledToFit()
                .frame(width: 92, height: 92)
                .accessibilityHidden(true)
            HStack(spacing: 0) {
                Text("iAdapt").foregroundStyle(theme.text)
                Text("Ops").foregroundStyle(theme.accentGradient)
            }
            .font(.system(size: 34, weight: .bold, design: .rounded))

            Text(t(mode == .signIn ? "auth.welcomeBack" : "auth.createSubtitle"))
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(theme.textDim)
        }
        .padding(.top, 4)
    }

    // MARK: - Email and password

    private var form: some View {
        VStack(spacing: 14) {
            modePicker

            if mode == .signUp {
                field(
                    "auth.name", icon: "person.fill", text: $name,
                    content: .name, focused: .name, next: .email
                )
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            field(
                "auth.email", icon: "envelope.fill", text: $email,
                content: .emailAddress, keyboard: .emailAddress, focused: .email, next: .password
            )

            passwordField

            if let key = formErrorKey ?? auth.errorKey {
                message(t(key), icon: "exclamationmark.circle.fill", color: theme.danger)
            } else if let key = auth.noticeKey {
                message(t(key), icon: "checkmark.circle.fill", color: theme.ok)
            }

            GradientButton(
                titleKey: mode == .signIn ? "auth.signIn" : "auth.createAccount",
                icon: mode == .signIn ? "arrow.right" : "sparkles",
                isEnabled: !auth.isWorking,
                action: submit
            )

            if mode == .signIn {
                Button(t("auth.forgotPassword")) {
                    formErrorKey = nil
                    Task { await auth.sendPasswordReset(email: email) }
                }
                .font(.footnote.weight(.semibold))
                .foregroundStyle(theme.accent)
            }
        }
        .padding(18)
        .panelBackground()
        .animation(theme.snappyAnimation, value: mode)
    }

    private var modePicker: some View {
        HStack(spacing: 4) {
            modeButton(.signIn, titleKey: "auth.signIn")
            modeButton(.signUp, titleKey: "auth.createAccount")
        }
        .padding(4)
        .background(Capsule().fill(theme.panel2))
    }

    private func modeButton(_ value: Mode, titleKey: String) -> some View {
        let isSelected = mode == value
        return Button {
            Haptics.selection()
            withAnimation(theme.snappyAnimation) {
                mode = value
                formErrorKey = nil
                auth.errorKey = nil
                auth.noticeKey = nil
            }
        } label: {
            Text(t(titleKey))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isSelected ? theme.onAccent : theme.textDim)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background {
                    if isSelected { Capsule().fill(theme.accentGradient) }
                }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    private func field(
        _ placeholderKey: String,
        icon: String,
        text: Binding<String>,
        content: UITextContentType,
        keyboard: UIKeyboardType = .default,
        focused: Field,
        next: Field
    ) -> some View {
        HStack(spacing: 11) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(theme.accent)
                .frame(width: 20)
            TextField(t(placeholderKey), text: text)
                .textContentType(content)
                .keyboardType(keyboard)
                .textInputAutocapitalization(focused == .name ? .words : .never)
                .autocorrectionDisabled()
                .focused($focus, equals: focused)
                .submitLabel(.next)
                .onSubmit { focus = next }
        }
        .fieldBackground(isFocused: focus == focused)
    }

    private var passwordField: some View {
        HStack(spacing: 11) {
            Image(systemName: "lock.fill")
                .font(.subheadline)
                .foregroundStyle(theme.accent)
                .frame(width: 20)
            Group {
                if showsPassword {
                    TextField(t("auth.password"), text: $password)
                } else {
                    SecureField(t("auth.password"), text: $password)
                }
            }
            .textContentType(mode == .signIn ? .password : .newPassword)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .focused($focus, equals: .password)
            .submitLabel(.go)
            .onSubmit(submit)

            Button {
                showsPassword.toggle()
            } label: {
                Image(systemName: showsPassword ? "eye.slash.fill" : "eye.fill")
                    .font(.subheadline)
                    .foregroundStyle(theme.textFaint)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(t(showsPassword ? "auth.hidePassword" : "auth.showPassword"))
        }
        .fieldBackground(isFocused: focus == .password)
    }

    private func message(_ text: String, icon: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
            Text(text)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .font(.footnote)
        .foregroundStyle(color)
    }

    private func submit() {
        focus = nil
        auth.errorKey = nil
        auth.noticeKey = nil
        formErrorKey = AuthValidation.problemKey(
            name: mode == .signUp ? name : nil,
            email: email,
            password: password
        )
        guard formErrorKey == nil else {
            Haptics.warning()
            return
        }
        Task {
            if mode == .signIn {
                await auth.signIn(email: email, password: password)
            } else {
                await auth.signUp(name: name, email: email, password: password)
            }
        }
    }

    // MARK: - Providers

    private var divider: some View {
        HStack(spacing: 12) {
            Rectangle().fill(theme.textFaint.opacity(0.3)).frame(height: 1)
            Text(t("auth.or"))
                .font(.caption.weight(.semibold))
                .foregroundStyle(theme.textFaint)
            Rectangle().fill(theme.textFaint.opacity(0.3)).frame(height: 1)
        }
    }

    private var providerButtons: some View {
        VStack(spacing: 12) {
            appleButton

            if FirebaseSetup.isGoogleAvailable {
                providerButton("auth.continueGoogle", mark: AnyView(GoogleMark())) {
                    Task { await auth.signInWithGoogle() }
                }
            }

            if FirebaseSetup.isMicrosoftAvailable {
                providerButton("auth.continueMicrosoft", mark: AnyView(MicrosoftMark())) {
                    Task { await auth.signInWithMicrosoft() }
                }
            }
        }
    }

    /// Built by hand so it follows the app's language; styled per Apple's
    /// guidelines: system font, Apple logo, black on light, white on dark.
    private var appleButton: some View {
        Button {
            Task { await auth.signInWithApple() }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "apple.logo")
                    .font(.system(size: 19, weight: .medium))
                Text(t("auth.continueApple"))
                    .font(.system(size: 17, weight: .semibold))
            }
            .foregroundStyle(theme.isDark ? Color.black : Color.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(theme.isDark ? Color.white : Color.black)
            )
        }
        .buttonStyle(PressableButtonStyle())
    }

    private func providerButton(_ titleKey: String, mark: AnyView, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                mark.frame(width: 18, height: 18)
                Text(t(titleKey))
                    .font(.system(size: 17, weight: .semibold))
            }
            .foregroundStyle(theme.text)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(theme.panel)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(theme.textFaint.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PressableButtonStyle())
    }

    private var privacyNote: some View {
        VStack(spacing: 6) {
            Text(t("auth.privacyNote"))
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundStyle(theme.textFaint)
            Link(t("auth.privacyLink"), destination: URL(string: "https://github.com/VidiPT89/iAdaptOps/blob/main/PRIVACY.md")!)
                .font(.caption.weight(.semibold))
                .foregroundStyle(theme.accent)
        }
        .padding(.bottom, 8)
    }

    // MARK: - Unavailable

    private var unavailableCard: some View {
        VStack(spacing: 14) {
            message(t("auth.unavailable"), icon: "icloud.slash.fill", color: theme.textDim)
            #if DEBUG
            OutlineButton(titleKey: "auth.continueGuest", icon: "person.crop.circle.dashed") {
                auth.continueAsGuest()
            }
            #endif
        }
        .padding(18)
        .panelBackground()
    }
}

private extension View {
    func fieldBackground(isFocused: Bool) -> some View {
        let theme = Theme.shared
        return self
            .font(.subheadline)
            .foregroundStyle(theme.text)
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(theme.panel2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(theme.accent.opacity(isFocused ? 0.6 : 0), lineWidth: 1.5)
            )
    }
}

/// The four-colour Google "G", drawn as arcs so no image asset is needed.
private struct GoogleMark: View {
    var body: some View {
        Canvas { context, size in
            let lineWidth = size.width * 0.2
            let rect = CGRect(origin: .zero, size: size).insetBy(dx: lineWidth / 2, dy: lineWidth / 2)
            let center = CGPoint(x: rect.midX, y: rect.midY)
            let radius = rect.width / 2
            let arcs: [(Double, Double, Color)] = [
                (-40, 45, Color(hex: 0x4285F4)),
                (45, 135, Color(hex: 0x34A853)),
                (135, 215, Color(hex: 0xFBBC05)),
                (215, 320, Color(hex: 0xEA4335))
            ]
            for (start, end, color) in arcs {
                var arc = Path()
                arc.addArc(center: center, radius: radius, startAngle: .degrees(start), endAngle: .degrees(end), clockwise: false)
                context.stroke(arc, with: .color(color), lineWidth: lineWidth)
            }
            var bar = Path()
            bar.move(to: center)
            bar.addLine(to: CGPoint(x: rect.maxX + lineWidth / 2, y: center.y))
            context.stroke(bar, with: .color(Color(hex: 0x4285F4)), lineWidth: lineWidth)
        }
        .accessibilityHidden(true)
    }
}

/// The Microsoft four-square logo.
private struct MicrosoftMark: View {
    var body: some View {
        let colors = [Color(hex: 0xF25022), Color(hex: 0x7FBA00), Color(hex: 0x00A4EF), Color(hex: 0xFFB900)]
        Grid(horizontalSpacing: 1.5, verticalSpacing: 1.5) {
            GridRow {
                Rectangle().fill(colors[0])
                Rectangle().fill(colors[1])
            }
            GridRow {
                Rectangle().fill(colors[2])
                Rectangle().fill(colors[3])
            }
        }
        .accessibilityHidden(true)
    }
}
