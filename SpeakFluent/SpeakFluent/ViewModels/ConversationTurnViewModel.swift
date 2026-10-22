import Foundation
import SwiftUI
import Combine

public enum TurnState: Equatable {
    case idle
    case userSpeaking
    case streamingToLLM
    case aiStreamingResponse(partialText: String)
    case aiSpeaking(fullText: String)
    case waitingForUser(adaptivePrompt: String)
    case error(String)

    public var statusTitle: String {
        switch self {
        case .idle: return "Ready to Converse"
        case .userSpeaking: return "Listening to You..."
        case .streamingToLLM: return "Analyzing Speech with AI..."
        case .aiStreamingResponse: return "AI Generating Response..."
        case .aiSpeaking: return "AI is Speaking..."
        case .waitingForUser: return "Your Turn to Respond"
        case .error: return "Attention Needed"
        }
    }
}

@MainActor
public final class ConversationTurnViewModel: ObservableObject {
    @Published public var state: TurnState = .idle
    @Published public var conversationHistory: [ConversationTurn] = []
    @Published public var liveUserSpeech: String = ""
    @Published public var streamingAIText: String = ""
    @Published public var latestEvaluation: LLMPronunciationEvaluation?
    @Published public var showEvaluationSheet: Bool = false
    @Published public var audioPower: Float = 0.0

    public let speechRecognizer: SpeechRecognizer
    public let ttsService: TextToSpeechService
    public let llmService: LLMServiceProtocol
    public let webSocketClient: WebSocketStreamingClient

    private var cancellables = Set<AnyCancellable>()

    public init(
        speechRecognizer: SpeechRecognizer? = nil,
        ttsService: TextToSpeechService? = nil,
        llmService: LLMServiceProtocol? = nil,
        webSocketClient: WebSocketStreamingClient? = nil
    ) {
        self.speechRecognizer = speechRecognizer ?? SpeechRecognizer()
        self.ttsService = ttsService ?? TextToSpeechService()
        self.llmService = llmService ?? GeminiLLMService()
        self.webSocketClient = webSocketClient ?? WebSocketStreamingClient()

        setupInitialGreeting()
        bindRecognizer()
    }

    private func setupInitialGreeting() {
        let greeting = "Hello there! I'm your AI English speaking coach. What's on your mind today, or what would you like to practice?"
        let initialTurn = ConversationTurn(speaker: .assistant, text: greeting)
        self.conversationHistory = [initialTurn]
        self.state = .waitingForUser(adaptivePrompt: greeting)
    }

    private func bindRecognizer() {
        speechRecognizer.$transcript
            .receive(on: DispatchQueue.main)
            .sink { [weak self] text in
                guard let self = self else { return }
                self.liveUserSpeech = text
            }
            .store(in: &cancellables)

        speechRecognizer.$audioLevel
            .receive(on: DispatchQueue.main)
            .sink { [weak self] level in
                guard let self = self else { return }
                self.audioPower = level
            }
            .store(in: &cancellables)

        ttsService.$isSpeaking
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isSpeaking in
                guard let self = self else { return }
                if !isSpeaking && self.state == .aiSpeaking(fullText: self.streamingAIText) {
                    if let eval = self.latestEvaluation {
                        self.state = .waitingForUser(adaptivePrompt: eval.adaptiveFollowUpPrompt)
                    } else {
                        self.state = .idle
                    }
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Turn-Taking Actions
    public func startUserTurn() async {
        ttsService.stop()
        liveUserSpeech = ""
        streamingAIText = ""

        let granted = await speechRecognizer.requestPermissions()
        guard granted else {
            state = .error("Microphone access is required for conversation.")
            return
        }

        do {
            try speechRecognizer.startRecording()
            state = .userSpeaking
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    public func finishUserTurnAndSubmit() {
        guard state == .userSpeaking else { return }
        speechRecognizer.stopRecording()

        let spokenText = liveUserSpeech.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !spokenText.isEmpty else {
            state = .idle
            return
        }

        // Add user turn to conversation history
        let userTurn = ConversationTurn(speaker: .user, text: spokenText)
        conversationHistory.append(userTurn)
        if conversationHistory.count > 30 {
            conversationHistory.removeFirst(conversationHistory.count - 30)
        }

        state = .streamingToLLM

        Task {
            await executeConversationalRoundTrip(userSpeech: spokenText)
        }
    }

    public func toggleUserSpeaking() {
        if state == .userSpeaking {
            finishUserTurnAndSubmit()
        } else {
            Task {
                await startUserTurn()
            }
        }
    }

    // MARK: - Ultra-Low Latency Conversational Round-Trip
    private func executeConversationalRoundTrip(userSpeech: String) async {
        do {
            // Step 1: Request structured LLM evaluation and reply in one fast call
            let (evaluation, replyText) = try await llmService.evaluateAndRespond(
                history: conversationHistory,
                userSpeech: userSpeech
            )

            self.latestEvaluation = evaluation

            // Attach evaluation to user's last turn
            if let lastIndex = conversationHistory.indices.last {
                conversationHistory[lastIndex].evaluation = evaluation
            }

            // Extract ONLY the clean conversational message to speak and display (never raw JSON)
            let rawCandidate = replyText.isEmpty ? evaluation.adaptiveFollowUpPrompt : replyText
            let cleanMessage = cleanSpokenMessage(from: rawCandidate)

            // Step 2: Stream the clean words into UI for smooth typewriter effect
            self.state = .aiStreamingResponse(partialText: "")
            self.streamingAIText = ""

            let words = cleanMessage.components(separatedBy: " ")
            for word in words {
                try? await Task.sleep(nanoseconds: 28_000_000) // 28ms per word
                self.streamingAIText += word + " "
                self.state = .aiStreamingResponse(partialText: self.streamingAIText)
            }

            let finalReply = cleanMessage

            // Step 3: Append AI turn to conversation history
            let aiTurn = ConversationTurn(speaker: .assistant, text: finalReply)
            conversationHistory.append(aiTurn)

            // Step 4: Voice Turn-Taking - AI speaks ONLY the natural spoken sentence
            self.state = .aiSpeaking(fullText: finalReply)
            ttsService.speak(text: finalReply)

        } catch {
            state = .error("LLM evaluation failed: \(error.localizedDescription)")
        }
    }

    private func cleanSpokenMessage(from raw: String) -> String {
        var text = raw.trimmingCharacters(in: .whitespacesAndNewlines)

        // Strip markdown code fences if present
        if text.hasPrefix("```") {
            let lines = text.components(separatedBy: .newlines)
            let filtered = lines.filter { !$0.trimmingCharacters(in: .whitespaces).hasPrefix("```") }
            text = filtered.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        }

        // If the string contains a raw JSON payload, extract the conversational follow-up
        if text.contains("{") && text.contains("}") {
            if let data = text.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                if let prompt = json["adaptiveFollowUpPrompt"] as? String, !prompt.isEmpty {
                    return prompt
                }
                if let reply = json["replyText"] as? String, !reply.isEmpty {
                    return reply
                }
                if let feedback = json["coachFeedback"] as? String, !feedback.isEmpty {
                    return feedback
                }
            }

            // Regex fallback for embedded key
            if let regex = try? NSRegularExpression(pattern: "\"adaptiveFollowUpPrompt\"\\s*:\\s*\"([^\"]+)\""),
               let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
               let range = Range(match.range(at: 1), in: text) {
                return String(text[range])
            }
        }

        return text
    }

    public func speakTurnText(_ text: String) {
        ttsService.speak(text: text)
    }

    public func resetConversation() {
        ttsService.stop()
        speechRecognizer.stopRecording()
        setupInitialGreeting()
        latestEvaluation = nil
        liveUserSpeech = ""
        streamingAIText = ""
    }
}
