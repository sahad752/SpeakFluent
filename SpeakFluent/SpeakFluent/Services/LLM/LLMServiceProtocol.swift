import Foundation

public protocol LLMServiceProtocol: AnyObject {
    /// Evaluates user speech with structured JSON output (score, phonetic mistakes, adaptive prompts)
    func evaluateAndRespond(
        history: [ConversationTurn],
        userSpeech: String
    ) async throws -> (evaluation: LLMPronunciationEvaluation, replyText: String)

    /// Streams conversational tokens in real-time for sub-second UI response
    func streamConversationTokens(
        history: [ConversationTurn],
        userSpeech: String
    ) -> AsyncThrowingStream<String, Error>
}
