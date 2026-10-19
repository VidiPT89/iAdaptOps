import SwiftUI
import WidgetKit

@main
struct iSpoonFitWidgetBundle: WidgetBundle {
    var body: some Widget {
        TodayWidget()
    }
}

/// Today's workout and the program's progress, on the home and lock screens.
struct TodayWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "TodayWidget", provider: TodayProvider()) { entry in
            TodayWidgetView(entry: entry)
                .containerBackground(for: .widget) { WidgetPalette.background }
        }
        .configurationDisplayName("iSpoonFit")
        .description(WidgetText.text("description", Locale.current.language.languageCode?.identifier ?? "pt"))
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular])
    }
}

struct TodayEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot?

    var status: WidgetSnapshot.Status { snapshot?.status(at: date) ?? .noProgram }
    var language: String { snapshot?.language ?? "pt" }
}

/// The app reloads the widget whenever its data changes; between those, one
/// entry per midnight is enough, since that is when the day's state can move
/// from rest day to workout or from "done" to the next session.
struct TodayProvider: TimelineProvider {
    func placeholder(in context: Context) -> TodayEntry {
        TodayEntry(date: .now, snapshot: .preview)
    }

    func getSnapshot(in context: Context, completion: @escaping (TodayEntry) -> Void) {
        completion(TodayEntry(date: .now, snapshot: WidgetSnapshot.load() ?? .preview))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TodayEntry>) -> Void) {
        let snapshot = WidgetSnapshot.load()
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        var entries = [TodayEntry(date: .now, snapshot: snapshot)]
        for offset in 1...7 {
            if let midnight = calendar.date(byAdding: .day, value: offset, to: today) {
                entries.append(TodayEntry(date: midnight, snapshot: snapshot))
            }
        }
        completion(Timeline(entries: entries, policy: .atEnd))
    }
}

// MARK: - Views

struct TodayWidgetView: View {
    let entry: TodayEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .accessoryCircular: circular
        case .accessoryRectangular: rectangular
        case .systemMedium: medium
        default: small
        }
    }

    private var snapshot: WidgetSnapshot? { entry.snapshot }
    private var language: String { entry.language }

    private func text(_ key: String) -> String { WidgetText.text(key, language) }
    private func text(_ key: String, _ value: Int) -> String { WidgetText.text(key, language, value) }

    private var headline: String {
        switch entry.status {
        case .noProgram: return "iSpoonFit"
        case .complete: return text("complete")
        case .startsIn(let days): return days == 1 ? text("startsTomorrow") : text("startsIn", days)
        case .doneToday: return text("doneToday")
        case .restDay: return text("restDay")
        case .workout: return text("workout")
        }
    }

    private var icon: String {
        switch entry.status {
        case .noProgram: return "figure.flexibility"
        case .complete: return "trophy.fill"
        case .startsIn: return "calendar.badge.clock"
        case .doneToday: return "checkmark.seal.fill"
        case .restDay: return "moon.stars.fill"
        case .workout: return "flame.fill"
        }
    }

    /// The session the card points at: today's on a training day, the next
    /// one otherwise.
    private var nextLine: String? {
        guard let next = snapshot?.next else {
            return entry.status == .noProgram ? text("noProgram") : nil
        }
        return next.title
    }

    private var detailLine: String? {
        guard let next = snapshot?.next else { return nil }
        let prefix = entry.status == .workout ? "" : text("upNext") + " · "
        return prefix + text("day", next.dayIndex) + " · \(next.minutes) min"
    }

    private var small: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top) {
                ProgressRingView(snapshot: snapshot, lineWidth: 6)
                    .frame(width: 46, height: 46)
                Spacer(minLength: 0)
                Image(systemName: icon)
                    .font(.headline)
                    .foregroundStyle(WidgetPalette.accent)
            }
            Spacer(minLength: 0)
            Text(headline)
                .font(.caption.weight(.semibold))
                .foregroundStyle(WidgetPalette.accent)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            if let nextLine {
                Text(nextLine)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(WidgetPalette.text)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private var medium: some View {
        HStack(spacing: 16) {
            VStack(spacing: 6) {
                ProgressRingView(snapshot: snapshot, lineWidth: 8)
                    .frame(width: 78, height: 78)
                Text(text("sessions"))
                    .font(.caption2)
                    .foregroundStyle(WidgetPalette.textDim)
            }
            VStack(alignment: .leading, spacing: 5) {
                Label(headline, systemImage: icon)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(WidgetPalette.accent)
                    .lineLimit(1)
                if let nextLine {
                    Text(nextLine)
                        .font(.headline)
                        .foregroundStyle(WidgetPalette.text)
                        .lineLimit(2)
                }
                if let detailLine {
                    Text(detailLine)
                        .font(.caption)
                        .foregroundStyle(WidgetPalette.textDim)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                if let next = snapshot?.next {
                    Text(text("week", next.week))
                        .font(.caption2)
                        .foregroundStyle(WidgetPalette.textDim)
                }
            }
            Spacer(minLength: 0)
        }
    }

    private var circular: some View {
        Gauge(value: snapshot?.progress ?? 0) {
            Image(systemName: "figure.flexibility")
        } currentValueLabel: {
            Text("\(snapshot?.completed ?? 0)")
        }
        .gaugeStyle(.accessoryCircularCapacity)
    }

    private var rectangular: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(headline)
                .font(.headline)
                .widgetAccentable()
                .lineLimit(1)
            if let nextLine {
                Text(nextLine)
                    .font(.caption)
                    .lineLimit(1)
            }
            Text("\(snapshot?.completed ?? 0)/\(snapshot?.total ?? 28)")
                .font(.caption2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct ProgressRingView: View {
    let snapshot: WidgetSnapshot?
    let lineWidth: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .stroke(WidgetPalette.accent.opacity(0.18), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: snapshot?.progress ?? 0)
                .stroke(
                    LinearGradient(
                        colors: [WidgetPalette.accentLight, WidgetPalette.accent],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            VStack(spacing: 0) {
                Text("\(snapshot?.completed ?? 0)")
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .foregroundStyle(WidgetPalette.text)
                Text("/\(snapshot?.total ?? 28)")
                    .font(.system(size: 9, weight: .medium, design: .rounded))
                    .foregroundStyle(WidgetPalette.textDim)
            }
        }
    }
}

/// The app's brand colors, following the system appearance.
enum WidgetPalette {
    // Same values as ThemePalette in the app.
    static let accent = Color(light: 0xb8590a, dark: 0xf99c00)
    static let accentLight = Color(light: 0xf99c00, dark: 0xfcbb00)
    static let background = Color(light: 0xf7f4ef, dark: 0x0a0a0f)
    static let text = Color(light: 0x17140f, dark: 0xe2e8f0)
    static let textDim = Color(light: 0x5c574f, dark: 0x94a3b8)
}

private extension Color {
    init(light: UInt32, dark: UInt32) {
        self.init(UIColor { traits in
            let hex = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(
                red: CGFloat((hex >> 16) & 0xff) / 255,
                green: CGFloat((hex >> 8) & 0xff) / 255,
                blue: CGFloat(hex & 0xff) / 255,
                alpha: 1
            )
        })
    }
}

private extension WidgetSnapshot {
    /// Shown in the widget gallery before the app has written anything.
    static let preview = WidgetSnapshot(
        language: Locale.current.language.languageCode?.identifier == "en" ? "en" : "pt",
        completed: 9,
        total: 28,
        startDate: .distantPast,
        lastWorkoutDate: nil,
        next: NextWorkout(dayIndex: 10, week: 3, title: "iSpoonFit", minutes: 14)
    )
}
