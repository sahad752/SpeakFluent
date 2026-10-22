import Foundation

public final class GeminiLLMService: LLMServiceProtocol {
    private let urlSession: URLSession
    private var config: LLMConfig { LLMConfig.shared }

    public init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
    }

    // MARK: - Structured Output Evaluation
    public func evaluateAndRespond(
        history: [ConversationTurn],
        userSpeech: String
    ) async throws -> (evaluation: LLMPronunciationEvaluation, replyText: String) {
        if config.isMockModeEnabled || config.apiKey.isEmpty {
            return generateMockEvaluation(history: history, userSpeech: userSpeech)
        }

        let endpoint = "\(config.customEndpoint)/models/\(config.modelName):generateContent?key=\(config.apiKey)"
        guard let url = URL(string: endpoint) else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let requestBody = buildStructuredRequestBody(history: history, userSpeech: userSpeech)
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await urlSession.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let errorText = String(data: data, encoding: .utf8) ?? "Unknown server response"
            throw NSError(domain: "GeminiAPI", code: (response as? HTTPURLResponse)?.statusCode ?? 500, userInfo: [NSLocalizedDescriptionKey: errorText])
        }

        return try parseStructuredResponse(data: data)
    }

    // MARK: - Streaming Tokens for Low-Latency Round-Trips
    public func streamConversationTokens(
        history: [ConversationTurn],
        userSpeech: String
    ) -> AsyncThrowingStream<String, Error> {
        return AsyncThrowingStream { continuation in
            Task {
                if self.config.isMockModeEnabled || self.config.apiKey.isEmpty {
                    // Simulate sub-second token streaming
                    let mockReply = self.generateMockEvaluation(history: history, userSpeech: userSpeech).replyText
                    let words = mockReply.components(separatedBy: " ")
                    for word in words {
                        try? await Task.sleep(nanoseconds: 60_000_000) // 60ms per word
                        continuation.yield(word + " ")
                    }
                    continuation.finish()
                    return
                }

                do {
                    let endpoint = "\(self.config.customEndpoint)/models/\(self.config.modelName):streamGenerateContent?alt=sse&key=\(self.config.apiKey)"
                    guard let url = URL(string: endpoint) else {
                        continuation.finish(throwing: URLError(.badURL))
                        return
                    }

                    var request = URLRequest(url: url)
                    request.httpMethod = "POST"
                    request.addValue("application/json", forHTTPHeaderField: "Content-Type")

                    let body = self.buildStreamingRequestBody(history: history, userSpeech: userSpeech)
                    request.httpBody = try JSONSerialization.data(withJSONObject: body)

                    let (bytes, response) = try await self.urlSession.bytes(for: request)
                    guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                        continuation.finish(throwing: URLError(.badServerResponse))
                        return
                    }

                    for try await line in bytes.lines {
                        if line.hasPrefix("data: ") {
                            let jsonString = String(line.dropFirst(6))
                            if let jsonData = jsonString.data(using: .utf8),
                               let partial = self.extractText(from: jsonData) {
                                continuation.yield(partial)
                            }
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    // MARK: - Request Builders
    private func buildStructuredRequestBody(history: [ConversationTurn], userSpeech: String) -> [String: Any] {
        var contents: [[String: Any]] = []

        for turn in history.suffix(6) {
            contents.append([
                "role": turn.speaker == .user ? "user" : "model",
                "parts": [["text": turn.text]]
            ])
        }

        let userPrompt = """
        User just spoke: "\(userSpeech)".
        Evaluate their pronunciation, phonetic clarity, and provide your conversational reply along with an adaptive follow-up prompt in the structured JSON schema.
        """
        contents.append([
            "role": "user",
            "parts": [["text": userPrompt]]
        ])

        return [
            "system_instruction": [
                "parts": [["text": LLMConfig.systemInstruction]]
            ],
            "contents": contents,
            "generationConfig": [
                "responseMimeType": "application/json",
                "responseSchema": LLMPronunciationEvaluation.jsonSchema,
                "temperature": 0.4
            ]
        ]
    }

    private func buildStreamingRequestBody(history: [ConversationTurn], userSpeech: String) -> [String: Any] {
        var contents: [[String: Any]] = []
        for turn in history.suffix(6) {
            contents.append([
                "role": turn.speaker == .user ? "user" : "model",
                "parts": [["text": turn.text]]
            ])
        }
        contents.append([
            "role": "user",
            "parts": [["text": "User says: \"\(userSpeech)\". Reply conversationally and briefly to keep the conversation going."]]
        ])

        return [
            "system_instruction": ["parts": [["text": LLMConfig.systemInstruction]]],
            "contents": contents,
            "generationConfig": ["temperature": 0.6]
        ]
    }

    // MARK: - Parsers
    private func parseStructuredResponse(data: Data) throws -> (evaluation: LLMPronunciationEvaluation, replyText: String) {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let firstCandidate = candidates.first,
              let content = firstCandidate["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let firstPart = parts.first,
              let text = firstPart["text"] as? String else {
            throw NSError(domain: "GeminiParser", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse candidates JSON"])
        }

        guard let structuredData = text.data(using: .utf8) else {
            throw NSError(domain: "GeminiParser", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid text encoding in LLM response"])
        }

        let eval = try JSONDecoder().decode(LLMPronunciationEvaluation.self, from: structuredData)
        let reply = "\(eval.adaptiveFollowUpPrompt)"
        return (eval, reply)
    }

    private func extractText(from data: Data) -> String? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let first = candidates.first,
              let content = first["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let text = parts.first?["text"] as? String else {
            return nil
        }
        return text
    }

    // MARK: - Realistic Mock Evaluation (Zero-Config Demos)
    private func generateMockEvaluation(
        history: [ConversationTurn],
        userSpeech: String
    ) -> (evaluation: LLMPronunciationEvaluation, replyText: String) {
        let clean = userSpeech.lowercased()
        var mistakes: [PhoneticMistake] = []

        if clean.contains("think") || clean.contains("the") || clean.contains("that") {
            mistakes.append(PhoneticMistake(
                word: "think",
                expectedIPA: "/θɪŋk/",
                heardSound: "[tɪŋk]",
                tip: "Place your tongue between your teeth for voiceless /θ/."
            ))
        }

        if clean.contains("really") || clean.contains("world") {
            mistakes.append(PhoneticMistake(
                word: "really",
                expectedIPA: "/ˈrɪəli/",
                heardSound: "[ˈliːəli]",
                tip: "Curl the tongue back without touching the roof of your mouth for /r/."
            ))
        }

        let score = mistakes.isEmpty ? 92 : 84
        let followUp: String
        let suggestedReply: String

        if clean.contains("hello") || clean.contains("hi") || clean.contains("morning") {
            followUp = "Good morning! How has your English speaking journey been going so far?"
            suggestedReply = "It's going well! I'm practicing every single day to gain confidence."
        } else if clean.contains("coffee") || clean.contains("food") || clean.contains("eat") {
            followUp = "That sounds delicious! Do you prefer ordering black coffee or a creamy latte?"
            suggestedReply = "I usually prefer a warm latte with oat milk in the morning."
        } else if clean.contains("work") || clean.contains("project") || clean.contains("job") {
            followUp = "Tell me more about your recent project. What was the most exciting milestone?"
            suggestedReply = "We recently deployed an iOS voice application with low latency streaming."
        } else {
            followUp = "That's very interesting! Could you elaborate on what you found most enjoyable about that experience?"
            suggestedReply = "I really enjoyed collaborating with a talented team of engineers."
        }

        let eval = LLMPronunciationEvaluation(
            overallScore: score,
            accuracy: score + 2,
            fluency: score - 1,
            coachFeedback: mistakes.isEmpty
                ? "Excellent flow and clear diction! Your sentence melody was very natural."
                : "Great conversational attempt! Focus on relaxing your tongue on initial consonants.",
            phoneticMistakes: mistakes,
            grammarCorrection: clean.contains("i have went") ? "Say 'I went' or 'I have gone' instead." : nil,
            adaptiveFollowUpPrompt: followUp,
            suggestedSampleReply: suggestedReply
        )

        return (eval, followUp)
    }
}
