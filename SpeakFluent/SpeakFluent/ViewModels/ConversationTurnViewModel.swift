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
        speechRecognizer: SpeechRecognizer = SpeechRecognizer(),
        ttsService: TextToSpeechService = TextToSpeechService(),
        llmService: LLMServiceProtocol = GeminiLLMService(),
        webSocketClient: WebSocketStreamingClient = WebSocketStreamingClient()
    ) {
        self.speechRecognizer = speechRecognizer
        self.ttsService = ttsService
        self.llmService = llmService
        self.webSocketClient = webSocketClient

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
            // Step 1: Request structured LLM evaluation and reply
            let (evaluation, replyText) = try await llmService.evaluateAndRespond(
                history: conversationHistory,
                userSpeech: userSpeech
            )

            self.latestEvaluation = evaluation

            // Attach evaluation to user's last turn
            if let lastIndex = conversationHistory.indices.last {
                conversationHistory[lastIndex].evaluation = evaluation
            }

            // Step 2: Stream tokens dynamically into UI for low-latency visual feedback
            self.state = .aiStreamingResponse(partialText: "")
            self.streamingAIText = ""

            let tokenStream = llmService.streamConversationTokens(
                history: conversationHistory,
                userSpeech: userSpeech
            )

            for try await token in tokenStream {
                self.streamingAIText += token
                self.state = .aiStreamingResponse(partialText: self.streamingAIText)
            }

            let finalReply = self.streamingAIText.isEmpty ? replyText : self.streamingAIText

            // Step 3: Append AI turn
            let aiTurn = ConversationTurn(speaker: .assistant, text: finalReply)
            conversationHistory.append(aiTurn)

            // Step 4: Voice Turn-Taking - AI speaks the response via AVFoundation TTS
            self.state = .aiSpeaking(fullText: finalReply)
            ttsService.speak(text: finalReply)

        } catch {
            state = .error("LLM evaluation failed: \(error.localizedDescription)")
        }
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
