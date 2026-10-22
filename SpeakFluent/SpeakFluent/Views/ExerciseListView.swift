import SwiftUI

public struct ExerciseListView: View {
    @ObservedObject public var hubViewModel: PracticeHubViewModel
    @ObservedObject public var coachViewModel: CoachViewModel
    @Binding public var selectedTab: Int

    public init(
        hubViewModel: PracticeHubViewModel,
        coachViewModel: CoachViewModel,
        selectedTab: Binding<Int>
    ) {
        self.hubViewModel = hubViewModel
        self.coachViewModel = coachViewModel
        self._selectedTab = selectedTab
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Search Bar
                    searchField

                    // Categories Horizontal Scroll
                    categoriesSection

                    // Difficulty Filter Chips
                    difficultyFilterRow

                    // Exercise List Items
                    exerciseCardsList
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Exercise Library")
        }
    }

    private var searchField: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            TextField("Search phrases, sounds, or words...", text: $hubViewModel.searchText)
                .autocorrectionDisabled()

            if !hubViewModel.searchText.isEmpty {
                Button(action: { hubViewModel.searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(12)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }

    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Categories")
                .font(.headline)
                .fontWeight(.bold)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    // "All" option card
                    allCategoryPill

                    ForEach(ExerciseCategory.allCases) { cat in
                        let count = hubViewModel.exercises.filter { $0.category == cat }.count
                        CategoryCard(
                            category: cat,
                            exerciseCount: count,
                            isSelected: hubViewModel.selectedCategory == cat,
                            onSelect: {
                                if hubViewModel.selectedCategory == cat {
                                    hubViewModel.selectedCategory = nil
                                } else {
                                    hubViewModel.selectedCategory = cat
                                }
                            }
                        )
                        .frame(width: 170)
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    private var allCategoryPill: some View {
        Button(action: {
            hubViewModel.selectedCategory = nil
        }) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(hubViewModel.selectedCategory == nil ? Color.white.opacity(0.25) : Color.blue.opacity(0.12))
                            .frame(width: 44, height: 44)

                        Image(systemName: "square.grid.2x2.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(hubViewModel.selectedCategory == nil ? .white : .blue)
                    }

                    Spacer()

                    Text("\(hubViewModel.exercises.count)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(hubViewModel.selectedCategory == nil ? Color.white.opacity(0.2) : Color.gray.opacity(0.12))
                        .foregroundColor(hubViewModel.selectedCategory == nil ? .white : .secondary)
                        .cornerRadius(8)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("All Categories")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(hubViewModel.selectedCategory == nil ? .white : .primary)

                    Text("Browse the entire collection")
                        .font(.caption)
                        .foregroundColor(hubViewModel.selectedCategory == nil ? .white.opacity(0.85) : .secondary)
                }
            }
            .padding(14)
            .frame(width: 170)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(
                        hubViewModel.selectedCategory == nil
                            ? LinearGradient(colors: [Color.blue, Color.indigo], startPoint: .topLeading, endPoint: .bottomTrailing)
                            : LinearGradient(colors: [Color(UIColor.secondarySystemBackground)], startPoint: .top, endPoint: .bottom)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(hubViewModel.selectedCategory == nil ? Color.white.opacity(0.4) : Color.gray.opacity(0.15), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var difficultyFilterRow: some View {
        HStack(spacing: 8) {
            filterChip(title: "All Levels", isSelected: hubViewModel.selectedDifficulty == nil) {
                hubViewModel.selectedDifficulty = nil
            }

            ForEach(DifficultyLevel.allCases) { diff in
                filterChip(title: diff.rawValue, isSelected: hubViewModel.selectedDifficulty == diff) {
                    if hubViewModel.selectedDifficulty == diff {
                        hubViewModel.selectedDifficulty = nil
                    } else {
                        hubViewModel.selectedDifficulty = diff
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func filterChip(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(isSelected ? Color.primary : Color(UIColor.secondarySystemBackground))
                .foregroundColor(isSelected ? Color(UIColor.systemBackground) : .secondary)
                .cornerRadius(20)
        }
    }

    private var exerciseCardsList: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Exercises (\(hubViewModel.filteredExercises.count))")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
            }

            if hubViewModel.filteredExercises.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary)
                    Text("No matching exercises found")
                        .font(.headline)
                    Text("Try adjusting your filters or search keywords.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                ForEach(hubViewModel.filteredExercises) { exercise in
                    exerciseRow(exercise)
                }
            }
        }
    }

    private func exerciseRow(_ exercise: PronunciationExercise) -> some View {
        Button(action: {
            coachViewModel.setExercise(exercise)
            selectedTab = 0 // Switch to Coach tab
        }) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(exercise.title)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)

                    Spacer()

                    Text(exercise.difficulty.rawValue)
                        .font(.caption2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(difficultyBadgeColor(exercise.difficulty).opacity(0.15))
                        .foregroundColor(difficultyBadgeColor(exercise.difficulty))
                        .cornerRadius(6)
                }

                Text(exercise.targetSentence)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineLimit(2)

                HStack {
                    HStack(spacing: 4) {
                        ForEach(exercise.focusPhonemes, id: \.self) { phoneme in
                            Text(phoneme)
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(Color.indigo.opacity(0.12))
                                .foregroundColor(.indigo)
                                .cornerRadius(4)
                        }
                    }

                    Spacer()

                    HStack(spacing: 4) {
                        Text("Practice")
                            .font(.caption)
                            .fontWeight(.semibold)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundColor(.blue)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(UIColor.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.gray.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func difficultyBadgeColor(_ difficulty: DifficultyLevel) -> Color {
        switch difficulty {
        case .beginner: return .green
        case .intermediate: return .orange
        case .advanced: return .purple
        }
    }
}
