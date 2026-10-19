import SwiftUI

struct HistoryView: View {
    let viewModel: ProgramViewModel

    @Environment(\.dismiss) private var dismiss
    @State private var pendingDeletion: CompletedSession?
    let theme = Theme.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                if viewModel.sessions.isEmpty {
                    Text(t("history.empty"))
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(theme.textFaint)
                        .padding(.horizontal, 32)
                        .padding(.top, 60)
                } else {
                    VStack(spacing: 11) {
                        ForEach(viewModel.sessions) { session in
                            row(session)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
            .scrollIndicators(.hidden)
            .background(theme.background.ignoresSafeArea())
            .navigationTitle(t("history.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(t("action.close")) { dismiss() }
                        .tint(theme.accent)
                }
            }
            .alert(
                t("history.deleteTitle"),
                isPresented: Binding(
                    get: { pendingDeletion != nil },
                    set: { if !$0 { pendingDeletion = nil } }
                )
            ) {
                Button(t("action.cancel"), role: .cancel) {}
                Button(t("action.delete"), role: .destructive) {
                    if let session = pendingDeletion {
                        withAnimation(theme.snappyAnimation) { viewModel.delete(session) }
                    }
                }
            } message: {
                Text(t("history.deleteBody"))
            }
        }
    }

    private func row(_ session: CompletedSession) -> some View {
        let day = viewModel.day(at: session.dayIndex)
        return HStack(alignment: .top, spacing: 13) {
            ZStack {
                Circle()
                    .fill(theme.accentGradient)
                    .frame(width: 42, height: 42)
                Text("\(session.dayIndex)")
                    .font(.subheadline.bold().monospacedDigit())
                    .foregroundStyle(theme.onAccent)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(day.map { t($0.titleKey) } ?? t("day.n", session.dayIndex))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(theme.text)

                Text(formatted(session.date))
                    .font(.caption)
                    .foregroundStyle(theme.textFaint)

                HStack(spacing: 7) {
                    ChipView(text: "\(session.minutes) min", icon: "clock.fill")
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

            Button {
                pendingDeletion = session
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

    private func formatted(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = LocalizationManager.shared.current.locale
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
