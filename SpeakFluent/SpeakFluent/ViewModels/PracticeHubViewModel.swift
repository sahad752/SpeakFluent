import Foundation
import SwiftUI
import Combine

@MainActor
public final class PracticeHubViewModel: ObservableObject {
    @Published public var exercises: [PronunciationExercise] = PronunciationExercise.sampleExercises
    @Published public var searchText: String = ""
    @Published public var selectedCategory: ExerciseCategory? = nil
    @Published public var selectedDifficulty: DifficultyLevel? = nil

    public init() {}

    public var filteredExercises: [PronunciationExercise] {
        exercises.filter { exercise in
            let matchesSearch = searchText.isEmpty ||
                exercise.title.localizedCaseInsensitiveContains(searchText) ||
                exercise.targetSentence.localizedCaseInsensitiveContains(searchText) ||
                exercise.tips.localizedCaseInsensitiveContains(searchText)

            let matchesCategory = selectedCategory == nil || exercise.category == selectedCategory
            let matchesDifficulty = selectedDifficulty == nil || exercise.difficulty == selectedDifficulty

            return matchesSearch && matchesCategory && matchesDifficulty
        }
    }
}
