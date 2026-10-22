import Foundation

public struct PhoneticMistake: Codable, Identifiable, Hashable {
    public var id: String { "\(word)_\(expectedIPA)" }
    public let word: String
    public let expectedIPA: String
    public let heardSound: String
    public let tip: String

    public init(word: String, expectedIPA: String, heardSound: String, tip: String) {
        self.word = word
        self.expectedIPA = expectedIPA
        self.heardSound = heardSound
        self.tip = tip
    }
}

public struct LLMPronunciationEvaluation: Codable, Hashable {
    public let overallScore: Int
    public let accuracy: Int
    public let fluency: Int
    public let coachFeedback: String
    public let phoneticMistakes: [PhoneticMistake]
    public let grammarCorrection: String?
    public let adaptiveFollowUpPrompt: String
    public let suggestedSampleReply: String

    public init(
        overallScore: Int,
        accuracy: Int,
        fluency: Int,
        coachFeedback: String,
        phoneticMistakes: [PhoneticMistake] = [],
        grammarCorrection: String? = nil,
        adaptiveFollowUpPrompt: String,
        suggestedSampleReply: String
    ) {
        self.overallScore = overallScore
        self.accuracy = accuracy
        self.fluency = fluency
        self.coachFeedback = coachFeedback
        self.phoneticMistakes = phoneticMistakes
        self.grammarCorrection = grammarCorrection
        self.adaptiveFollowUpPrompt = adaptiveFollowUpPrompt
        self.suggestedSampleReply = suggestedSampleReply
    }

    /// JSON Schema definition used for Gemini & OpenAI Structured Outputs
    public static var jsonSchema: [String: Any] {
        return [
            "type": "OBJECT",
            "properties": [
                "overallScore": ["type": "INTEGER", "description": "Score from 0 to 100"],
                "accuracy": ["type": "INTEGER", "description": "Pronunciation accuracy score 0 to 100"],
                "fluency": ["type": "INTEGER", "description": "Fluency and natural rhythm score 0 to 100"],
                "coachFeedback": ["type": "STRING", "description": "Encouraging, actionable pronunciation coaching note"],
                "phoneticMistakes": [
                    "type": "ARRAY",
                    "items": [
                        "type": "OBJECT",
                        "properties": [
                            "word": ["type": "STRING"],
                            "expectedIPA": ["type": "STRING"],
                            "heardSound": ["type": "STRING"],
                            "tip": ["type": "STRING"]
                        ],
                        "required": ["word", "expectedIPA", "heardSound", "tip"]
                    ]
                ],
                "grammarCorrection": ["type": "STRING", "description": "Optional grammar refinement or natural phrasing"],
                "adaptiveFollowUpPrompt": ["type": "STRING", "description": "Natural conversation follow-up question guiding learner"],
                "suggestedSampleReply": ["type": "STRING", "description": "Sample sentence the user could reply with"]
            ],
            "required": ["overallScore", "accuracy", "fluency", "coachFeedback", "phoneticMistakes", "adaptiveFollowUpPrompt", "suggestedSampleReply"]
        ]
    }
}

public enum SpeakerType: String, Codable {
    case user
    case assistant
}

public struct ConversationTurn: Identifiable, Codable {
    public let id: UUID
    public let speaker: SpeakerType
    public let text: String
    public let timestamp: Date
    public var evaluation: LLMPronunciationEvaluation?

    public init(
        id: UUID = UUID(),
        speaker: SpeakerType,
        text: String,
        timestamp: Date = Date(),
        evaluation: LLMPronunciationEvaluation? = nil
    ) {
        self.id = id
        self.speaker = speaker
        self.text = text
        self.timestamp = timestamp
        self.evaluation = evaluation
    }
}
