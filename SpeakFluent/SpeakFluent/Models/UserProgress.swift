import Foundation

public struct UserBadge: Identifiable, Codable {
    public let id: String
    public let title: String
    public let description: String
    public let iconName: String
    public let isUnlocked: Bool

    public init(id: String, title: String, description: String, iconName: String, isUnlocked: Bool) {
        self.id = id
        self.title = title
        self.description = description
        self.iconName = iconName
        self.isUnlocked = isUnlocked
    }
}

public struct DailyPracticeRecord: Identifiable, Codable {
    public let id: UUID
    public let date: Date
    public let exercisesCompleted: Int
    public let averageAccuracy: Double

    public init(id: UUID = UUID(), date: Date, exercisesCompleted: Int, averageAccuracy: Double) {
        self.id = id
        self.date = date
        self.exercisesCompleted = exercisesCompleted
        self.averageAccuracy = averageAccuracy
    }
}

public struct UserProgress: Codable {
    public var currentStreak: Int
    public var longestStreak: Int
    public var totalPracticedPhrases: Int
    public var totalSpeakingSeconds: Int
    public var averageScore: Double
    public var lastPracticeDate: Date?
    public var history: [SpeechAnalysisResult]

    public init(
        currentStreak: Int = 3,
        longestStreak: Int = 7,
        totalPracticedPhrases: Int = 24,
        totalSpeakingSeconds: Int = 780,
        averageScore: Double = 86.5,
        lastPracticeDate: Date? = Date(),
        history: [SpeechAnalysisResult] = []
    ) {
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.totalPracticedPhrases = totalPracticedPhrases
        self.totalSpeakingSeconds = totalSpeakingSeconds
        self.averageScore = averageScore
        self.lastPracticeDate = lastPracticeDate
        self.history = history
    }

    public static let standardBadges: [UserBadge] = [
        UserBadge(id: "first_word", title: "First Words", description: "Completed your first speech practice session.", iconName: "sparkles", isUnlocked: true),
        UserBadge(id: "streak_3", title: "3-Day Flame", description: "Practiced for 3 consecutive days.", iconName: "flame.fill", isUnlocked: true),
        UserBadge(id: "accuracy_90", title: "Master Speaker", description: "Achieved 90%+ pronunciation accuracy.", iconName: "star.fill", isUnlocked: true),
        UserBadge(id: "twister_champ", title: "Tongue Acrobat", description: "Conquered 3 tongue twisters with >85% accuracy.", iconName: "bolt.fill", isUnlocked: false),
        UserBadge(id: "streak_7", title: "Unstoppable", description: "Maintain a 7-day speaking streak.", iconName: "trophy.fill", isUnlocked: false)
    ]
}
