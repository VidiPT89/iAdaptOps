import SwiftUI

struct SessionCompleteView: View {
    let day: ProgramDay
    let durationSeconds: Int
    let daysDone: Int
    let lowEnergy: Bool
    let offersProgramLink: Bool
    let onFinish: (_ energy: Int?, _ discomfort: Int?, _ note: String?, _ showProgram: Bool) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var energy: Int?
    @State private var discomfort: Int?
    @State private var note = ""
    @State private var checkmarkIn = false

    let theme = Theme.shared

    var body: some View {
        ZStack {
            if day.isFinalDay && !reduceMotion {
                ConfettiView()
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }

            ScrollView {
                VStack(spacing: 20) {
                    badge
                    headline
                    stats
                    checkIn
                    GradientButton(titleKey: "action.done", icon: "checkmark") {
                        finish(showProgram: false)
                    }
                    if offersProgramLink {
                        OutlineButton(titleKey: "session.viewProgram", icon: "calendar") {
                            finish(showProgram: true)
                        }
                    }
                }
                .padding(.horizontal, 22)
                .padding(.vertical, 28)
            }
            .scrollIndicators(.hidden)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.1)) {
                checkmarkIn = true
            }
        }
    }

    /// Matches the limit enforced by the database rules.
    static let noteLimit = 500

    private func finish(showProgram: Bool) {
        let trimmed = String(note.trimmingCharacters(in: .whitespacesAndNewlines).prefix(Self.noteLimit))
        onFinish(energy, discomfort, trimmed.isEmpty ? nil : trimmed, showProgram)
    }

    // MARK: - Pieces

    private var badge: some View {
        ZStack {
            Circle()
                .fill(theme.accentGradient)
                .frame(width: 112, height: 112)
                .shadow(color: theme.accent.opacity(0.45), radius: 24, y: 8)

            Image(systemName: day.isFinalDay ? "trophy.fill" : "checkmark")
                .font(.system(size: 46, weight: .bold))
                .foregroundStyle(theme.onAccent)
                .symbolEffect(.bounce, options: .nonRepeating, value: checkmarkIn)
        }
        .scaleEffect(checkmarkIn ? 1 : 0.5)
        .opacity(checkmarkIn ? 1 : 0)
        .padding(.top, 10)
    }

    private var headline: some View {
        VStack(spacing: 8) {
            Text(t(day.isFinalDay ? "session.finalTitle" : "session.done"))
                .font(.title2.bold())
                .multilineTextAlignment(.center)
                .foregroundStyle(theme.text)

            Text(day.isFinalDay ? t("session.finalBody") : t(day.titleKey))
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(theme.textDim)
        }
    }

    private var stats: some View {
        HStack(spacing: 10) {
            statTile(
                value: "\(max(1, Int((Double(durationSeconds) / 60).rounded())))",
                unit: "min",
                labelKey: "session.totalTime",
                icon: "clock.fill"
            )
            statTile(
                value: "\(daysDone)",
                unit: "/ \(ProgramData.totalDays)",
                labelKey: "today.daysDone",
                icon: "flame.fill"
            )
            if lowEnergy {
                statTile(value: "🍃", unit: "", labelKey: "lowEnergy.title", icon: "leaf.fill")
            }
        }
    }

    private func statTile(value: String, unit: String, labelKey: String, icon: String) -> some View {
        VStack(spacing: 5) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(theme.accent)
                .symbolRenderingMode(.hierarchical)
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(value)
                    .font(.title3.bold().monospacedDigit())
                    .foregroundStyle(theme.text)
                if !unit.isEmpty {
                    Text(unit)
                        .font(.caption2)
                        .foregroundStyle(theme.textFaint)
                }
            }
            Text(t(labelKey))
                .font(.caption2)
                .multilineTextAlignment(.center)
                .foregroundStyle(theme.textFaint)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .panelBackground()
    }

    private var checkIn: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 3) {
                Text(t("checkin.title"))
                    .font(.headline)
                    .foregroundStyle(theme.text)
                Text(t("checkin.optional"))
                    .font(.caption)
                    .foregroundStyle(theme.textFaint)
            }

            scale(titleKey: "checkin.energy", range: 1...5, selection: $energy)
            scale(titleKey: "checkin.discomfort", range: 0...10, selection: $discomfort)

            VStack(alignment: .leading, spacing: 7) {
                Text(t("checkin.note"))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(theme.textDim)
                TextField(t("checkin.notePlaceholder"), text: $note, axis: .vertical)
                    .font(.subheadline)
                    .lineLimit(1...3)
                    .onChange(of: note) { _, value in
                        if value.count > Self.noteLimit { note = String(value.prefix(Self.noteLimit)) }
                    }
                    .padding(11)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(theme.panel2)
                    )
            }
        }
        .padding(18)
        .panelBackground()
    }

    private func scale(titleKey: String, range: ClosedRange<Int>, selection: Binding<Int?>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(t(titleKey))
                .font(.caption.weight(.semibold))
                .foregroundStyle(theme.textDim)

            HStack(spacing: 5) {
                ForEach(Array(range), id: \.self) { value in
                    let isSelected = selection.wrappedValue == value
                    Button {
                        Haptics.selection()
                        withAnimation(theme.snappyAnimation) {
                            selection.wrappedValue = isSelected ? nil : value
                        }
                    } label: {
                        Text("\(value)")
                            .font(.caption.weight(.semibold).monospacedDigit())
                            .foregroundStyle(isSelected ? theme.onAccent : theme.textDim)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 9)
                            .background {
                                if isSelected {
                                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                                        .fill(theme.accentGradient)
                                } else {
                                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                                        .fill(theme.panel2)
                                }
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

/// Discreet orange and yellow confetti for the final day, drawn in a Canvas so
/// it costs nothing when it is not on screen.
struct ConfettiView: View {
    private let pieces: [Piece] = (0..<70).map { index in
        var generator = SeededGenerator(seed: UInt64(index &* 2_654_435_761))
        return Piece(
            x: Double.random(in: 0...1, using: &generator),
            delay: Double.random(in: 0...1.6, using: &generator),
            duration: Double.random(in: 2.4...4.2, using: &generator),
            drift: Double.random(in: -0.12...0.12, using: &generator),
            size: Double.random(in: 4...9, using: &generator),
            spin: Double.random(in: 1...4, using: &generator),
            tone: Int.random(in: 0...2, using: &generator)
        )
    }

    /// Held in state so re-rendering the parent (tapping a check-in score,
    /// typing a note) does not restart the fall from the top.
    @State private var start = Date()
    /// Every piece has faded out after three falls, so the timeline stops
    /// redrawing instead of animating an empty canvas forever.
    @State private var isDone = false
    let theme = Theme.shared

    struct Piece {
        let x: Double
        let delay: Double
        let duration: Double
        let drift: Double
        let size: Double
        let spin: Double
        let tone: Int
    }

    var body: some View {
        TimelineView(.animation(paused: isDone)) { timeline in
            Canvas { context, size in
                let elapsed = timeline.date.timeIntervalSince(start)
                for piece in pieces {
                    let local = elapsed - piece.delay
                    guard local > 0 else { continue }
                    let progress = (local / piece.duration).truncatingRemainder(dividingBy: 1)
                    let fade = local > piece.duration * 3 ? 0 : 1.0

                    let x = (piece.x + piece.drift * progress) * size.width
                    let y = progress * (size.height + 40) - 20
                    let rect = CGRect(
                        x: x - piece.size / 2,
                        y: y - piece.size / 2,
                        width: piece.size,
                        height: piece.size * 1.6
                    )

                    var layer = context
                    layer.translateBy(x: rect.midX, y: rect.midY)
                    layer.rotate(by: .radians(progress * piece.spin * 2 * .pi))
                    layer.translateBy(x: -rect.midX, y: -rect.midY)
                    layer.opacity = fade
                    layer.fill(
                        Path(roundedRect: rect, cornerRadius: 1.5),
                        with: .color(color(for: piece.tone))
                    )
                }
            }
        }
        .task {
            try? await Task.sleep(for: .seconds(15))
            isDone = true
        }
    }

    private func color(for tone: Int) -> Color {
        switch tone {
        case 0: return theme.accentLight
        case 1: return theme.accent
        default: return theme.accentDark
        }
    }
}

/// Keeps the confetti layout identical on every launch, so the effect looks
/// designed rather than random.
private struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) { state = seed == 0 ? 0x9E3779B97F4A7C15 : seed }

    mutating func next() -> UInt64 {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }
}
