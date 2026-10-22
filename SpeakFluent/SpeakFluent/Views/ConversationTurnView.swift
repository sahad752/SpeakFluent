import SwiftUI

public struct ConversationTurnView: View {
    @ObservedObject public var viewModel: ConversationTurnViewModel
    @State private var showingSettingsSheet: Bool = false
    @State private var pulsingGlow: Bool = false

    public init(viewModel: ConversationTurnViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Turn State Indicator Banner
                    turnStatusBanner

                    // Scrollable Chat Dialogue History
                    chatHistoryScrollView

                    // Live Speech Preview Box (if user is speaking)
                    if viewModel.state == .userSpeaking && !viewModel.liveUserSpeech.isEmpty {
                        liveSpeechOverlay
                    }

                    // Adaptive Follow-Up Prompt Bar (if AI offered a prompt)
                    if let eval = viewModel.latestEvaluation {
                        adaptivePromptSuggestion(eval: eval)
                    }

                    // Voice Controls & Turn-Taking Button
                    bottomControlBar
                }
            }
            .navigationTitle("AI Voice Partner")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: {
                        viewModel.resetConversation()
                    }) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.subheadline)
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        showingSettingsSheet = true
                    }) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.subheadline)
                    }
                }
            }
            .sheet(isPresented: $showingSettingsSheet) {
                LLMSettingsSheet()
                    .presentationDetents([.medium])
            }
        }
    }

    // MARK: - Subviews
    private var turnStatusBanner: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)

            Text(viewModel.state.statusTitle)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(statusColor)

            Spacer()

            if viewModel.webSocketClient.latencyMs > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 9))
                    Text("\(viewModel.webSocketClient.latencyMs) ms")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                }
                .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(UIColor.secondarySystemBackground))
    }

    private var chatHistoryScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(viewModel.conversationHistory) { turn in
                        chatBubble(for: turn)
                            .id(turn.id)
                    }

                    // Streaming AI Response Box
                    if case .aiStreamingResponse(let text) = viewModel.state, !text.isEmpty {
                        HStack(alignment: .top, spacing: 10) {
                            aiAvatar

                            VStack(alignment: .leading, spacing: 4) {
                                Text(text)
                                    .font(.body)
                                    .foregroundColor(.primary)

                                HStack(spacing: 4) {
                                    Text("Streaming tokens...")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    ProgressView()
                                        .scaleEffect(0.6)
                                }
                            }
                            .padding(14)
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(18)

                            Spacer()
                        }
                    }
                }
                .padding(16)
            }
            .onChange(of: viewModel.conversationHistory.count) { _ in
                if let lastId = viewModel.conversationHistory.last?.id {
                    withAnimation {
                        proxy.scrollTo(lastId, anchor: .bottom)
                    }
                }
            }
        }
    }

    private func chatBubble(for turn: ConversationTurn) -> some View {
        VStack(alignment: turn.speaker == .user ? .trailing : .leading, spacing: 6) {
            HStack(alignment: .top, spacing: 8) {
                if turn.speaker == .assistant {
                    aiAvatar
                }

                VStack(alignment: turn.speaker == .user ? .trailing : .leading, spacing: 8) {
                    Text(turn.text)
                        .font(.body)
                        .foregroundColor(turn.speaker == .user ? .white : .primary)

                    // Pronunciation Structured Output Pill attached to user speech
                    if let eval = turn.evaluation {
                        evaluationPill(eval: eval)
                    }
                }
                .padding(14)
                .background(
                    turn.speaker == .user
                        ? AnyShapeStyle(LinearGradient(colors: [.blue, .indigo], startPoint: .topLeading, endPoint: .bottomTrailing))
                        : AnyShapeStyle(Color(UIColor.secondarySystemBackground))
                )
                .cornerRadius(18)

                if turn.speaker == .user {
                    userAvatar
                }
            }

            // Audio Replay button for AI turns
            if turn.speaker == .assistant {
                Button(action: {
                    viewModel.speakTurnText(turn.text)
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "speaker.wave.2.fill")
                        Text("Listen again")
                    }
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.leading, 42)
                }
            }
        }
    }

    private func evaluationPill(eval: LLMPronunciationEvaluation) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Divider()
                .overlay(Color.white.opacity(0.3))

            HStack {
                Label("\(eval.overallScore)% Pronunciation", systemImage: "sparkles")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.yellow)

                Spacer()

                Text("Accuracy: \(eval.accuracy)%")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.85))
            }

            if !eval.phoneticMistakes.isEmpty {
                VStack(alignment: .leading, spacing: 3) {
                    ForEach(eval.phoneticMistakes) { mistake in
                        Text("• \(mistake.word): \(mistake.expectedIPA) (heard: \(mistake.heardSound))")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.white.opacity(0.9))
                    }
                }
            }

            Text(eval.coachFeedback)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.9))
                .lineLimit(2)
        }
        .padding(.top, 4)
    }

    private var liveSpeechOverlay: some View {
        HStack(spacing: 8) {
            Image(systemName: "waveform")
                .foregroundColor(.red)
            Text(viewModel.liveUserSpeech)
                .font(.subheadline)
                .foregroundColor(.primary)
                .lineLimit(2)
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(UIColor.secondarySystemBackground))
                .shadow(radius: 4)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    private func adaptivePromptSuggestion(eval: LLMPronunciationEvaluation) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.orange)
                    .font(.caption)
                Text("Suggested Reply:")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
            }

            Text("\"\(eval.suggestedSampleReply)\"")
                .font(.caption)
                .foregroundColor(.primary)
                .italic()
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(10)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    private var bottomControlBar: some View {
        VStack(spacing: 8) {
            ZStack {
                if viewModel.state == .userSpeaking {
                    Circle()
                        .stroke(Color.red.opacity(0.35), lineWidth: 8)
                        .frame(width: 86, height: 86)
                        .scaleEffect(pulsingGlow ? 1.25 : 1.0)
                        .opacity(pulsingGlow ? 0.0 : 1.0)
                        .onAppear {
                            withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: false)) {
                                pulsingGlow = true
                            }
                        }
                }

                Button(action: {
                    viewModel.toggleUserSpeaking()
                }) {
                    ZStack {
                        Circle()
                            .fill(
                                viewModel.state == .userSpeaking
                                    ? LinearGradient(colors: [.red, .pink], startPoint: .topLeading, endPoint: .bottomTrailing)
                                    : LinearGradient(colors: [.blue, .indigo], startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                            .frame(width: 72, height: 72)
                            .shadow(color: viewModel.state == .userSpeaking ? Color.red.opacity(0.4) : Color.blue.opacity(0.3), radius: 10, y: 5)

                        if viewModel.state == .streamingToLLM {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.2)
                        } else {
                            Image(systemName: viewModel.state == .userSpeaking ? "stop.fill" : "mic.fill")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                }
            }

            Text(viewModel.state == .userSpeaking ? "Tap to Finish Speaking" : "Tap to Speak to AI")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity)
        .background(Color(UIColor.secondarySystemBackground))
    }

    private var aiAvatar: some View {
        ZStack {
            Circle()
                .fill(LinearGradient(colors: [.purple, .indigo], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 34, height: 34)

            Image(systemName: "sparkles")
                .font(.system(size: 16))
                .foregroundColor(.white)
        }
    }

    private var userAvatar: some View {
        ZStack {
            Circle()
                .fill(Color.blue.opacity(0.2))
                .frame(width: 34, height: 34)

            Image(systemName: "person.fill")
                .font(.system(size: 16))
                .foregroundColor(.blue)
        }
    }

    private var statusColor: Color {
        switch viewModel.state {
        case .idle, .waitingForUser: return .green
        case .userSpeaking: return .red
        case .streamingToLLM, .aiStreamingResponse: return .blue
        case .aiSpeaking: return .purple
        case .error: return .orange
        }
    }
}

// MARK: - LLM Settings Sheet
private struct LLMSettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var apiKey: String = LLMConfig.shared.apiKey
    @State private var isMockMode: Bool = LLMConfig.shared.isMockModeEnabled

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("LLM API Configuration"), footer: Text("Enter a Google Gemini API key for live LLM streaming. If empty, the app runs in realistic zero-latency local simulation mode.")) {
                    SecureField("Gemini API Key", text: $apiKey)
                        .autocorrectionDisabled()

                    Toggle("Enable Zero-Latency Demo Mode", isOn: $isMockMode)
                }

                Section(header: Text("Pipeline Architecture")) {
                    HStack {
                        Text("LLM Model")
                        Spacer()
                        Text("gemini-1.5-flash")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Output Format")
                        Spacer()
                        Text("JSON Schema Structured")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Streaming Protocol")
                        Spacer()
                        Text("SSE / WebSockets")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("AI Engine Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        var conf = LLMConfig.shared
                        conf.apiKey = apiKey
                        conf.isMockModeEnabled = isMockMode
                        dismiss()
                    }
                    .fontWeight(.bold)
                }
            }
        }
    }
}
