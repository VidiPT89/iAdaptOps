import SwiftUI

struct ExerciseLibraryView: View {
    @State private var category: ExerciseCategory?
    @State private var query = ""

    let theme = Theme.shared

    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 14)]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    ScreenHeader(titleKey: "tab.exercises")
                        .padding(.top, 8)

                    searchField
                    categoryFilter

                    if filtered.isEmpty {
                        Text(t("exercises.empty"))
                            .font(.subheadline)
                            .foregroundStyle(theme.textFaint)
                            .padding(.top, 40)
                    } else {
                        LazyVGrid(columns: columns, spacing: 14) {
                            ForEach(filtered) { exercise in
                                NavigationLink(value: exercise.id) {
                                    card(exercise)
                                }
                                .buttonStyle(PressableButtonStyle(scale: 0.97))
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
            .background(theme.background.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: ExerciseID.self) { id in
                ExerciseDetailView(ref: ExerciseRef(id))
            }
        }
    }

    private var filtered: [Exercise] {
        ExerciseCatalog.all.filter { exercise in
            let matchesCategory = category == nil || exercise.category == category
            guard matchesCategory else { return false }
            guard !query.isEmpty else { return true }
            // "gemeos" should still find "Elevação de gémeos".
            return t(exercise.nameKey).range(
                of: query,
                options: [.caseInsensitive, .diacriticInsensitive],
                locale: LocalizationManager.shared.current.locale
            ) != nil
        }
    }

    private var searchField: some View {
        HStack(spacing: 9) {
            Image(systemName: "magnifyingglass")
                .font(.subheadline)
                .foregroundStyle(theme.textFaint)
            TextField(t("exercises.searchPlaceholder"), text: $query)
                .font(.subheadline)
                .foregroundStyle(theme.text)
                .autocorrectionDisabled()
            if !query.isEmpty {
                Button {
                    query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(theme.textFaint)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(theme.panel2)
        )
    }

    private var categoryFilter: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 9) {
                filterChip(nil, titleKey: "category.all", icon: "square.grid.2x2.fill")
                ForEach(ExerciseCategory.allCases) { item in
                    filterChip(item, titleKey: item.titleKey, icon: item.icon)
                }
            }
            .padding(.vertical, 2)
        }
        .scrollIndicators(.hidden)
    }

    private func filterChip(_ item: ExerciseCategory?, titleKey: String, icon: String) -> some View {
        let isSelected = category == item
        return Button {
            Haptics.selection()
            withAnimation(theme.snappyAnimation) { category = item }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption2.weight(.semibold))
                    .symbolRenderingMode(.hierarchical)
                Text(t(titleKey))
                    .font(.caption.weight(.semibold))
            }
            .foregroundStyle(isSelected ? theme.onAccent : theme.textDim)
            .padding(.horizontal, 13)
            .padding(.vertical, 8)
            .background {
                if isSelected {
                    Capsule().fill(theme.accentGradient)
                } else {
                    Capsule().fill(theme.panel2)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func card(_ exercise: Exercise) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            ExerciseDemoView(motion: exercise.motion, lineWidth: 3.2, cycleDuration: exercise.motion.defaultCycleDuration)
                .frame(height: 104)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(theme.panel2)
                )

            Text(t(exercise.nameKey))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(theme.text)
                .multilineTextAlignment(.leading)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(t(exercise.category.titleKey))
                .font(.caption2)
                .foregroundStyle(theme.accent)
        }
        .padding(12)
        .panelBackground()
    }
}
