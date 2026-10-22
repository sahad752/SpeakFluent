import Foundation
import SwiftUI
import Combine

@MainActor
public final class ProgressViewModel: ObservableObject {
    @Published public var userProgress: UserProgress = UserProgress()
    @Published public var badges: [UserBadge] = UserProgress.standardBadges

    private let storageKey = "com.speakfluent.userprogress"

    public init() {
        loadProgress()
    }

    public func recordSession(result: SpeechAnalysisResult) {
        userProgress.totalPracticedPhrases += 1
        userProgress.totalSpeakingSeconds += 15 // approximate speaking time per attempt

        // Recompute average score
        let count = Double(userProgress.totalPracticedPhrases)
        let oldTotal = userProgress.averageScore * (count - 1)
        userProgress.averageScore = (oldTotal + Double(result.overallScore)) / count

        // Update streak
        let calendar = Calendar.current
        if let lastDate = userProgress.lastPracticeDate {
            if calendar.isDateInYesterday(lastDate) {
                userProgress.currentStreak += 1
                if userProgress.currentStreak > userProgress.longestStreak {
                    userProgress.longestStreak = userProgress.currentStreak
                }
            } else if !calendar.isDateInToday(lastDate) {
                userProgress.currentStreak = 1
            }
        } else {
            userProgress.currentStreak = 1
        }
        userProgress.lastPracticeDate = Date()

        // Append to history (keep recent 30)
        userProgress.history.insert(result, at: 0)
        if userProgress.history.count > 30 {
            userProgress.history.removeLast()
        }

        checkBadges()
        saveProgress()
    }

    private func checkBadges() {
        var updated = badges
        for i in 0..<updated.count {
            if updated[i].id == "first_word" && userProgress.totalPracticedPhrases >= 1 {
                updated[i] = UserBadge(id: updated[i].id, title: updated[i].title, description: updated[i].description, iconName: updated[i].iconName, isUnlocked: true)
            } else if updated[i].id == "streak_3" && userProgress.currentStreak >= 3 {
                updated[i] = UserBadge(id: updated[i].id, title: updated[i].title, description: updated[i].description, iconName: updated[i].iconName, isUnlocked: true)
            } else if updated[i].id == "accuracy_90" && userProgress.averageScore >= 90.0 {
                updated[i] = UserBadge(id: updated[i].id, title: updated[i].title, description: updated[i].description, iconName: updated[i].iconName, isUnlocked: true)
            } else if updated[i].id == "streak_7" && userProgress.currentStreak >= 7 {
                updated[i] = UserBadge(id: updated[i].id, title: updated[i].title, description: updated[i].description, iconName: updated[i].iconName, isUnlocked: true)
            }
        }
        self.badges = updated
    }

    private func saveProgress() {
        if let data = try? JSONEncoder().encode(userProgress) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func loadProgress() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let saved = try? JSONDecoder().decode(UserProgress.self, from: data) {
            self.userProgress = saved
        }
    }

    public func resetProgress() {
        self.userProgress = UserProgress(
            currentStreak: 0,
            longestStreak: 0,
            totalPracticedPhrases: 0,
            totalSpeakingSeconds: 0,
            averageScore: 0.0,
            lastPracticeDate: nil,
            history: []
        )
        saveProgress()
    }
}
