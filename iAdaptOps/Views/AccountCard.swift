import SwiftUI

/// The Settings card for the signed-in account: who is signed in and how,
/// sign-out, and permanent deletion (which the App Store requires for any
/// app that lets people create an account).
struct AccountCard: View {
    let auth: AuthService
    let viewModel: ProgramViewModel
    let onAccountDeleted: () -> Void

    @State private var confirmsSignOut = false
    @State private var confirmsDeletion = false
    @State private var showsAdmin = false

    let theme = Theme.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            SectionHeader(titleKey: "settings.account", icon: "person.crop.circle.fill")

            if let user = auth.user {
                identity(user)
            }

            if let user = auth.user, user.email != nil, !user.isEmailVerified, user != .localGuest {
                HStack(spacing: 8) {
                    Image(systemName: "envelope.badge")
                        .foregroundStyle(theme.accent)
                    Text(t("auth.emailUnverified"))
                        .foregroundStyle(theme.textDim)
                    Spacer(minLength: 0)
                    Button(t("auth.resend")) {
                        Task { await auth.resendVerification() }
                    }
                    .foregroundStyle(theme.accent)
                    .fontWeight(.semibold)
                }
                .font(.caption)
            }

            if let key = auth.noticeKey {
                Text(t(key))
                    .font(.caption)
                    .foregroundStyle(theme.ok)
            }

            if auth.user?.isAdmin == true {
                row("admin.title", icon: "shield.lefthalf.filled", tint: theme.text) {
                    showsAdmin = true
                }
            }

            if let key = auth.errorKey {
                Text(t(key))
                    .font(.caption)
                    .foregroundStyle(theme.danger)
                    .fixedSize(horizontal: false, vertical: true)
            }

            row("auth.signOut", icon: "rectangle.portrait.and.arrow.right", tint: theme.text) {
                confirmsSignOut = true
            }

            if auth.user != .localGuest {
                row("auth.deleteAccount", icon: "trash.fill", tint: theme.danger) {
                    auth.errorKey = nil
                    confirmsDeletion = true
                }
            }
        }
        .padding(18)
        .panelBackground()
        .sheet(isPresented: $showsAdmin) { AdminView() }
        .alert(t("auth.signOutTitle"), isPresented: $confirmsSignOut) {
            Button(t("action.cancel"), role: .cancel) {}
            Button(t("auth.signOut")) { auth.signOut() }
        } message: {
            Text(t("auth.signOutBody"))
        }
        .alert(t("auth.deleteTitle"), isPresented: $confirmsDeletion) {
            Button(t("action.cancel"), role: .cancel) {}
            Button(t("auth.deleteAccount"), role: .destructive) {
                Task {
                    let deleted = await auth.deleteAccount(removeData: viewModel.deleteCloudData)
                    if deleted { onAccountDeleted() }
                }
            }
        } message: {
            Text(t("auth.deleteBody"))
        }
    }

    private func identity(_ user: AccountUser) -> some View {
        HStack(spacing: 13) {
            ZStack {
                Circle()
                    .fill(theme.accentGradient)
                    .frame(width: 46, height: 46)
                Text(initials(user))
                    .font(.headline.bold())
                    .foregroundStyle(theme.onAccent)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(user.name ?? user.email ?? t("auth.guest"))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(theme.text)
                    .lineLimit(1)
                if user.name != nil, let email = user.email {
                    Text(email)
                        .font(.caption)
                        .foregroundStyle(theme.textDim)
                        .lineLimit(1)
                }
                if user != .localGuest {
                    Text(t(user.providerLabelKey))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(theme.accent)
                }
            }
            Spacer(minLength: 0)
        }
    }

    private func initials(_ user: AccountUser) -> String {
        let source = user.name ?? user.email ?? "?"
        let letters = source.split(separator: " ").prefix(2).compactMap(\.first)
        return String(letters).uppercased()
    }

    private func row(_ titleKey: String, icon: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 11) {
                Image(systemName: icon)
                    .font(.footnote)
                    .foregroundStyle(tint == theme.text ? theme.accent : tint)
                    .frame(width: 22)
                Text(t(titleKey))
                    .font(.subheadline)
                    .foregroundStyle(tint)
                Spacer()
            }
            .contentShape(Rectangle())
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
        .disabled(auth.isWorking)
    }
}
