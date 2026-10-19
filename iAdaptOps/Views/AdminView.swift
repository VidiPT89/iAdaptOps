import SwiftUI

/// The admin panel: every account with its progress, and profiles prepared
/// ahead of time by email. Opened from Settings, and only offered to the admin.
struct AdminView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var admin = AdminService()
    @State private var showsInviteForm = false
    @State private var pendingDeletion: AdminInvite?

    let theme = Theme.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    if let key = admin.errorKey {
                        Text(t(key))
                            .font(.footnote)
                            .foregroundStyle(theme.danger)
                    }
                    usersSection
                    invitesSection
                }
                .padding(20)
            }
            .scrollIndicators(.hidden)
            .background(theme.background.ignoresSafeArea())
            .navigationTitle(t("admin.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(t("action.close")) { dismiss() }
                        .tint(theme.accent)
                }
            }
            .navigationDestination(for: String.self) { userID in
                AdminUserDetailView(admin: admin, userID: userID)
            }
            .overlay {
                if admin.isLoading && admin.users.isEmpty {
                    ProgressView().tint(theme.accent)
                }
            }
            .refreshable { await admin.load() }
            .task { await admin.load() }
            .sheet(isPresented: $showsInviteForm) {
                AdminInviteForm(admin: admin)
            }
            .alert(
                t("admin.deleteInviteTitle"),
                isPresented: Binding(
                    get: { pendingDeletion != nil },
                    set: { if !$0 { pendingDeletion = nil } }
                )
            ) {
                Button(t("action.cancel"), role: .cancel) {}
                Button(t("action.delete"), role: .destructive) {
                    if let invite = pendingDeletion {
                        Task { await admin.deleteInvite(invite) }
                    }
                }
            } message: {
                Text(pendingDeletion?.email ?? "")
            }
        }
    }

    // MARK: - Accounts

    private var usersSection: some View {
        VStack(alignment: .leading, spacing: 11) {
            SectionHeader(titleKey: "admin.accounts", icon: "person.2.fill")
            if admin.users.isEmpty && !admin.isLoading {
                Text(t("admin.noAccounts"))
                    .font(.subheadline)
                    .foregroundStyle(theme.textFaint)
            }
            ForEach(admin.users) { user in
                NavigationLink(value: user.id) {
                    userRow(user)
                }
                .buttonStyle(PressableButtonStyle(scale: 0.985))
            }
        }
    }

    private func userRow(_ user: AdminUserSummary) -> some View {
        HStack(spacing: 13) {
            ProgressRing(
                progress: Double(user.completedDays) / Double(ProgramData.totalDays),
                lineWidth: 5,
                centerText: "\(user.completedDays)"
            )
            .frame(width: 46, height: 46)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(user.name ?? user.email ?? user.id)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(theme.text)
                        .lineLimit(1)
                    if user.email == AdminPolicy.email {
                        ChipView(text: t("admin.roleAdmin"), filled: true)
                    }
                }
                if let email = user.email, user.name != nil {
                    Text(email)
                        .font(.caption)
                        .foregroundStyle(theme.textDim)
                        .lineLimit(1)
                }
                Text(lastWorkoutLabel(user))
                    .font(.caption2)
                    .foregroundStyle(theme.textFaint)
            }
            Spacer(minLength: 0)
            if user.variant.isFixed {
                Image(systemName: "star.fill")
                    .font(.caption)
                    .foregroundStyle(theme.accent)
                    .accessibilityLabel(t(user.variant.titleKey))
            }
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(theme.textFaint)
        }
        .padding(14)
        .panelBackground()
    }

    private func lastWorkoutLabel(_ user: AdminUserSummary) -> String {
        guard let date = user.lastWorkout else { return t("admin.noWorkoutsYet") }
        return t("admin.lastWorkout", AdminFormat.date(date))
    }

    // MARK: - Invites

    private var invitesSection: some View {
        VStack(alignment: .leading, spacing: 11) {
            SectionHeader(titleKey: "admin.invites", icon: "envelope.badge.fill")
            Text(t("admin.invitesHint"))
                .font(.caption)
                .foregroundStyle(theme.textDim)
                .fixedSize(horizontal: false, vertical: true)

            ForEach(admin.invites) { invite in
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(invite.name ?? invite.email)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(theme.text)
                        if invite.name != nil {
                            Text(invite.email)
                                .font(.caption)
                                .foregroundStyle(theme.textDim)
                        }
                        ChipView(text: t(invite.variant.titleKey), icon: "list.bullet.rectangle")
                    }
                    Spacer(minLength: 0)
                    Button {
                        pendingDeletion = invite
                    } label: {
                        Image(systemName: "trash")
                            .font(.caption)
                            .foregroundStyle(theme.textFaint)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(t("action.delete"))
                }
                .padding(14)
                .panelBackground()
            }

            OutlineButton(titleKey: "admin.newInvite", icon: "plus") {
                showsInviteForm = true
            }
        }
    }
}

/// Prepares a profile for someone who has not signed in yet.
private struct AdminInviteForm: View {
    let admin: AdminService

    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var name = ""
    @State private var variant: ProgramVariant = .personalized

    let theme = Theme.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    TextField(t("auth.email"), text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .adminField()
                    TextField(t("auth.name"), text: $name)
                        .textContentType(.name)
                        .adminField()

                    SectionHeader(titleKey: "admin.program", icon: "list.bullet.rectangle")
                    VariantPicker(selection: $variant)

                    if let key = admin.errorKey {
                        Text(t(key))
                            .font(.footnote)
                            .foregroundStyle(theme.danger)
                    }

                    GradientButton(titleKey: "admin.saveInvite", icon: "checkmark") {
                        Task {
                            let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                            if await admin.saveInvite(email: email, name: trimmed.isEmpty ? nil : trimmed, variant: variant) {
                                dismiss()
                            }
                        }
                    }
                }
                .padding(20)
            }
            .background(theme.background.ignoresSafeArea())
            .navigationTitle(t("admin.newInvite"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(t("action.cancel")) { dismiss() }
                        .tint(theme.accent)
                }
            }
        }
        .presentationDetents([.large])
    }
}

/// One button per program variant, with its short description.
struct VariantPicker: View {
    @Binding var selection: ProgramVariant
    let theme = Theme.shared

    var body: some View {
        VStack(spacing: 10) {
            ForEach(ProgramVariant.allCases) { variant in
                let isSelected = selection == variant
                Button {
                    Haptics.selection()
                    withAnimation(theme.snappyAnimation) { selection = variant }
                } label: {
                    HStack(alignment: .top, spacing: 11) {
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(isSelected ? theme.accent : theme.textFaint)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(t(variant.titleKey))
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(theme.text)
                            Text(t(variant.descriptionKey))
                                .font(.caption)
                                .foregroundStyle(theme.textDim)
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(14)
                    .panelBackground(highlighted: isSelected)
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? [.isSelected] : [])
            }
        }
    }
}

@MainActor
enum AdminFormat {
    static func date(_ date: Date, time: Bool = false) -> String {
        let formatter = DateFormatter()
        formatter.locale = LocalizationManager.shared.current.locale
        formatter.dateStyle = .medium
        formatter.timeStyle = time ? .short : .none
        return formatter.string(from: date)
    }
}

private extension View {
    @MainActor
    func adminField() -> some View {
        let theme = Theme.shared
        return self
            .font(.subheadline)
            .foregroundStyle(theme.text)
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(theme.panel2)
            )
    }
}
