import Foundation

public enum WordAccuracyStatus: String, Codable {
    case perfect = "Perfect"      // 90 - 100%
    case good = "Good"            // 75 - 89%
    case needsWork = "Needs Work" // 50 - 74%
    case missed = "Missed"        // < 50%

    public var colorName: String {
        switch self {
        case .perfect: return "emerald"
        case .good: return "blue"
        case .needsWork: return "amber"
        case .missed: return "rose"
        }
    }

    public var systemIcon: String {
        switch self {
        case .perfect: return "checkmark.seal.fill"
        case .good: return "checkmark.circle.fill"
        case .needsWork: return "exclamationmark.circle.fill"
        case .missed: return "xmark.circle.fill"
        }
    }
}

public struct WordAnalysis: Identifiable, Codable, Hashable {
    public let id: UUID
    public let targetWord: String
    public let spokenWord: String?
    public let score: Double // 0.0 - 100.0
    public let status: WordAccuracyStatus
    public let feedback: String
    public let phoneticHint: String?

    public init(
        id: UUID = UUID(),
        targetWord: String,
        spokenWord: String?,
        score: Double,
        status: WordAccuracyStatus,
        feedback: String,
        phoneticHint: String? = nil
    ) {
        self.id = id
        self.targetWord = targetWord
        self.spokenWord = spokenWord
        self.score = score
        self.status = status
        self.feedback = feedback
        self.phoneticHint = phoneticHint
    }
}

public struct SpeechAnalysisResult: Identifiable, Codable {
    public let id: UUID
    public let date: Date
    public let targetSentence: String
    public let transcribedSentence: String
    public let overallScore: Int // 0 - 100
    public let pronunciationAccuracy: Int
    public let fluencyScore: Int
    public let completenessScore: Int
    public let words: [WordAnalysis]
    public let coachTip: String

    public init(
        id: UUID = UUID(),
        date: Date = Date(),
        targetSentence: String,
        transcribedSentence: String,
        overallScore: Int,
        pronunciationAccuracy: Int,
        fluencyScore: Int,
        completenessScore: Int,
        words: [WordAnalysis],
        coachTip: String
    ) {
        self.id = id
        self.date = date
        self.targetSentence = targetSentence
        self.transcribedSentence = transcribedSentence
        self.overallScore = overallScore
        self.pronunciationAccuracy = pronunciationAccuracy
        self.fluencyScore = fluencyScore
        self.completenessScore = completenessScore
        self.words = words
        self.coachTip = coachTip
    }
}

// MARK: - Sample Preview Result
extension SpeechAnalysisResult {
    public static let sample: SpeechAnalysisResult = {
        let words = [
            WordAnalysis(targetWord: "Could", spokenWord: "Could", score: 96, status: .perfect, feedback: "Clean soft plosive sound.", phoneticHint: "/kʊd/"),
            WordAnalysis(targetWord: "you", spokenWord: "you", score: 94, status: .perfect, feedback: "Smooth vowel glide.", phoneticHint: "/juː/"),
            WordAnalysis(targetWord: "please", spokenWord: "please", score: 92, status: .perfect, feedback: "Long 'ee' vowel maintained nicely.", phoneticHint: "/pliːz/"),
            WordAnalysis(targetWord: "pass", spokenWord: "pass", score: 88, status: .good, feedback: "A bit rushed on the ending sibilant.", phoneticHint: "/pæs/"),
            WordAnalysis(targetWord: "me", spokenWord: "me", score: 95, status: .perfect, feedback: "Clear and natural.", phoneticHint: "/miː/"),
            WordAnalysis(targetWord: "a", spokenWord: "a", score: 90, status: .perfect, feedback: "Proper unstressed schwa /ə/.", phoneticHint: "/ə/"),
            WordAnalysis(targetWord: "cup", spokenWord: "cup", score: 82, status: .good, feedback: "Good, release the 'p' gently.", phoneticHint: "/kʌp/"),
            WordAnalysis(targetWord: "of", spokenWord: "of", score: 70, status: .needsWork, feedback: "Pronounce softly as /əv/ rather than a harsh 'off'.", phoneticHint: "/əv/"),
            WordAnalysis(targetWord: "black", spokenWord: "black", score: 91, status: .perfect, feedback: "Crisp ending 'ck'.", phoneticHint: "/blæk/"),
            WordAnalysis(targetWord: "coffee?", spokenWord: "coffee", score: 94, status: .perfect, feedback: "Nice stress on first syllable.", phoneticHint: "/ˈkɒfi/")
        ]
        return SpeechAnalysisResult(
            targetSentence: "Could you please pass me a cup of black coffee?",
            transcribedSentence: "Could you please pass me a cup of black coffee",
            overallScore: 89,
            pronunciationAccuracy: 91,
            fluencyScore: 88,
            completenessScore: 100,
            words: words,
            coachTip: "Great rhythm! Pay close attention to weak prepositions like 'of' (/əv/) so your speech flows naturally."
        )
    }()
}
