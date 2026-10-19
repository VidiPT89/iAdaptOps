import SwiftUI

struct MainTabView: View {
    let viewModel: ProgramViewModel
    let auth: AuthService
    let onAccountDeleted: () -> Void

    @State private var selection: Tab = Self.initialTab
    @Namespace private var indicator

    let theme = Theme.shared

    private static var initialTab: Tab {
        #if DEBUG
        switch DebugLaunch.tab {
        case "program": return .program
        case "exercises": return .exercises
        case "settings": return .settings
        default: return .today
        }
        #else
        return .today
        #endif
    }

    enum Tab: Int, CaseIterable, Identifiable {
        case today, program, exercises, settings

        var id: Int { rawValue }

        var titleKey: String {
            switch self {
            case .today: return "tab.today"
            case .program: return "tab.program"
            case .exercises: return "tab.exercises"
            case .settings: return "tab.settings"
            }
        }

        var icon: String {
            switch self {
            case .today: return "sun.max.fill"
            case .program: return "calendar"
            case .exercises: return "figure.flexibility"
            case .settings: return "gearshape.fill"
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                switch selection {
                case .today:
                    TodayView(viewModel: viewModel, firstName: auth.user?.firstName) {
                        withAnimation(theme.snappyAnimation) { selection = .program }
                    }
                case .program: ProgramView(viewModel: viewModel)
                case .exercises: ExerciseLibraryView()
                case .settings:
                    SettingsView(viewModel: viewModel, auth: auth, onAccountDeleted: onAccountDeleted)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .transition(.opacity)

            tabBar
        }
        .background {
            ZStack {
                theme.background
                theme.backgroundWash
            }
            .ignoresSafeArea()
        }
    }

    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(Tab.allCases) { tab in
                tabItem(tab)
            }
        }
        .padding(.top, 10)
        .padding(.bottom, 6)
        // Like the system tab bar, the labels grow only so far: at the
        // accessibility sizes four of them no longer fit side by side.
        .dynamicTypeSize(...DynamicTypeSize.xxLarge)
        .background {
            theme.panel
                .overlay(
                    Rectangle()
                        .fill(theme.accent.opacity(0.10))
                        .frame(height: 1),
                    alignment: .top
                )
                .ignoresSafeArea(edges: .bottom)
        }
    }

    private func tabItem(_ tab: Tab) -> some View {
        let isSelected = selection == tab
        return Button {
            guard !isSelected else { return }
            Haptics.selection()
            withAnimation(theme.snappyAnimation) { selection = tab }
        } label: {
            VStack(spacing: 5) {
                ZStack {
                    if isSelected {
                        Capsule()
                            .fill(theme.accent.opacity(0.16))
                            .frame(width: 52, height: 30)
                            .matchedGeometryEffect(id: "tabIndicator", in: indicator)
                    }
                    Image(systemName: tab.icon)
                        .font(.system(size: 19))
                        .symbolRenderingMode(.hierarchical)
                        .symbolEffect(.bounce, value: isSelected)
                }
                .frame(height: 30)

                Text(t(tab.titleKey))
                    .font(.caption2.weight(isSelected ? .semibold : .regular))
            }
            .foregroundStyle(isSelected ? theme.accent : theme.textFaint)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("tab.\(tab.rawValue)")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}
