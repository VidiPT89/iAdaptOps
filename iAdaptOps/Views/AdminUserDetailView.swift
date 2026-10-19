import SwiftUI

/// One account in the admin panel: its program, its progress and every
/// workout with the check-in that came with it.
struct AdminUserDetailView: View {
    let admin: AdminService
    let userID: String

    let theme = Theme.shared

    private var user: AdminUserSummary? { admin.users.first { $0.id == userID } }

    var body: some View {
        ScrollView {
            if let user {
                VStack(alignment: .leading, spacing: 18) {
                    header(user)
                    programSection(user)
                    sessionsSection(user)
                }
                .padding(20)
            }
        }
        .scrollIndicators(.hidden)
        .background(theme.background.ignoresSafeArea())
        .navigationTitle(user?.name ?? user?.email ?? "")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func header(_ user: AdminUserSummary) -> some View {
        HStack(spacing: 16) {
            ProgressRing(
                progress: Double(user.completedDays) / Double(ProgramData.totalDays),
                lineWidth: 8,
                centerText: "\(user.completedDays)",
                centerCaption: t("today.ofTotal", ProgramData.totalDays)
            )
            .frame(width: 76, height: 76)

            VStack(alignment: .leading, spacing: 4) {
                Text(user.name ?? user.email ?? user.id)
                    .font(.headline)
                    .foregroundStyle(theme.text)
                if let email = user.email {
                    Text(email)
                        .font(.caption)
                        .foregroundStyle(theme.textDim)
                }
                if let start = user.startDate {
                    Text(t("admin.startedOn", AdminFormat.date(start)))
                        .font(.caption)
                        .foregroundStyle(theme.textFaint)
                } else {
                    Text(t("admin.notStarted"))
                        .font(.caption)
                        .foregroundStyle(theme.textFaint)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(18)
        .panelBackground()
    }

    private func programSection(_ user: AdminUserSummary) -> some View {
        VStack(alignment: .leading, spacing: 11) {
            SectionHeader(titleKey: "admin.program", icon: "list.bullet.rectangle")
            VariantPicker(selection: Binding(
                get: { user.variant },
                set: { variant in Task { await admin.setVariant(variant, for: user.id) } }
            ))
        }
    }

    private func sessionsSection(_ user: AdminUserSummary) -> some View {
        VStack(alignment: .leading, spacing: 11) {
            SectionHeader(titleKey: "history.title", icon: "clock.arrow.circlepath")
            if user.sessions.isEmpty {
                Text(t("admin.noWorkoutsYet"))
                    .font(.subheadline)
                    .foregroundStyle(theme.textFaint)
            }
            // Titles come from the plan; generated once, not once per row.
            let days = user.variant.days(profile: nil)
            ForEach(user.sortedSessions, id: \.id) { session in
                sessionRow(session, days: days)
            }
        }
    }

    private func sessionRow(_ session: RemoteSession, days: [ProgramDay]) -> some View {
        HStack(alignment: .top, spacing: 13) {
            ZStack {
                Circle()
                    .fill(theme.accentGradient)
                    .frame(width: 38, height: 38)
                Text("\(session.dayIndex)")
                    .font(.subheadline.bold().monospacedDigit())
                    .foregroundStyle(theme.onAccent)
            }
            VStack(alignment: .leading, spacing: 5) {
                Text(days.first { $0.index == session.dayIndex }.map { t($0.titleKey) } ?? t("day.n", session.dayIndex))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(theme.text)
                Text(AdminFormat.date(session.date, time: true))
                    .font(.caption)
                    .foregroundStyle(theme.textFaint)
                HStack(spacing: 7) {
                    ChipView(text: "\(max(1, Int((Double(session.durationSeconds) / 60).rounded()))) min", icon: "clock.fill")
                    if session.lowEnergy {
                        ChipView(text: t("lowEnergy.title"), icon: "leaf.fill", tint: theme.ok)
                    }
                    if let energy = session.energy {
                        ChipView(text: t("history.energyLabel", energy), icon: "bolt.fill")
                    }
                    if let discomfort = session.discomfort, discomfort > 0 {
                        ChipView(text: t("history.discomfortLabel", discomfort), icon: "bandage.fill", tint: theme.danger)
                    }
                }
                if let note = session.note, !note.isEmpty {
                    Text(note)
                        .font(.caption)
                        .foregroundStyle(theme.textDim)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .panelBackground()
    }
}
