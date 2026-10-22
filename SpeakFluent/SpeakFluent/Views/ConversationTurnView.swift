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
    @State private var selectedModel: String = LLMConfig.shared.cleanModelName
    @State private var isMockMode: Bool = LLMConfig.shared.isMockModeEnabled
    @State private var isTesting: Bool = false
    @State private var testResult: String?
    @State private var isSuccess: Bool = false

    var body: some View {
        NavigationStack {
            Form {
                Section(
                    header: Text("LLM API Configuration"),
                    footer: Text("Enter a Google Gemini API key from aistudio.google.com. Tapping 'Test' automatically discovers the latest active model provisioned for your key.")
                ) {
                    SecureField("Gemini API Key", text: $apiKey)
                        .autocorrectionDisabled()
                        .onChange(of: apiKey) { newKey in
                            if !newKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                isMockMode = false
                            }
                        }

                    Toggle("Enable Zero-Latency Demo Mode", isOn: $isMockMode)

                    Button(action: testApiKeyConnection) {
                        HStack {
                            if isTesting {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "network")
                            }
                            Text(isTesting ? "Discovering Models..." : "Test Gemini API Connection")
                        }
                    }
                    .disabled(apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isTesting)

                    if let result = testResult {
                        HStack(spacing: 6) {
                            Image(systemName: isSuccess ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                .foregroundColor(isSuccess ? .green : .red)
                            Text(result)
                                .font(.caption)
                                .foregroundColor(isSuccess ? .green : .red)
                        }
                    }
                }

                Section(header: Text("Pipeline Architecture")) {
                    HStack {
                        Text("Active Model")
                        Spacer()
                        Text(selectedModel)
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.blue)
                    }

                    HStack {
                        Text("Output Format")
                        Spacer()
                        Text("JSON Schema Structured")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Mode Status")
                        Spacer()
                        Text(isMockMode ? "Offline Demo Mode" : "Live Gemini Cloud")
                            .fontWeight(.semibold)
                            .foregroundColor(isMockMode ? .orange : .green)
                    }
                }
            }
            .navigationTitle("AI Engine Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        var conf = LLMConfig.shared
                        let trimmed = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
                        conf.apiKey = trimmed
                        conf.modelName = selectedModel
                        if trimmed.isEmpty {
                            conf.isMockModeEnabled = true
                        } else {
                            conf.isMockModeEnabled = isMockMode
                        }
                        dismiss()
                    }
                    .fontWeight(.bold)
                }
            }
        }
    }

    private func testApiKeyConnection() {
        let trimmed = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        isTesting = true
        testResult = nil

        Task {
            // Step 1: Query ListModels to find active models supported by user's key
            let listUrlString = "https://generativelanguage.googleapis.com/v1beta/models?key=\(trimmed)"
            guard let listUrl = URL(string: listUrlString) else {
                await updateTestStatus(success: false, message: "Invalid URL")
                return
            }

            var activeModel = self.selectedModel
            do {
                let (listData, listResponse) = try await URLSession.shared.data(from: listUrl)
                let statusCode = (listResponse as? HTTPURLResponse)?.statusCode ?? 500

                if statusCode == 200,
                   let json = try? JSONSerialization.jsonObject(with: listData) as? [String: Any],
                   let modelsArray = json["models"] as? [[String: Any]] {

                    // Filter models that support generateContent
                    let contentModels = modelsArray.compactMap { dict -> String? in
                        guard let name = dict["name"] as? String,
                              let methods = dict["supportedGenerationMethods"] as? [String],
                              methods.contains("generateContent") else {
                            return nil
                        }
                        return name.hasPrefix("models/") ? String(name.dropFirst(7)) : name
                    }

                    // Choose preferred flash model (e.g. 2.5, 2.0, 1.5, or first available)
                    if let bestFlash = contentModels.first(where: { $0.contains("flash") }) {
                        activeModel = bestFlash
                    } else if let first = contentModels.first {
                        activeModel = first
                    }
                }
            } catch {
                print("List models lookup warning: \(error.localizedDescription)")
            }

            // Step 2: Test generateContent on the selected model
            let generateEndpoint = "https://generativelanguage.googleapis.com/v1beta/models/\(activeModel):generateContent?key=\(trimmed)"
            guard let generateUrl = URL(string: generateEndpoint) else {
                await updateTestStatus(success: false, message: "Invalid generateContent URL")
                return
            }

            var request = URLRequest(url: generateUrl)
            request.httpMethod = "POST"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")

            let body: [String: Any] = [
                "contents": [
                    ["role": "user", "parts": [["text": "Say 'hello' in one word."]]]
                ]
            ]

            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: body)
                let (data, response) = try await URLSession.shared.data(for: request)
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 500

                if statusCode == 200 {
                    await MainActor.run {
                        self.isTesting = false
                        self.isSuccess = true
                        self.isMockMode = false
                        self.selectedModel = activeModel
                        LLMConfig.shared.modelName = activeModel
                        self.testResult = "Connected to \(activeModel)!"
                    }
                } else {
                    let json = (try? JSONSerialization.jsonObject(with: data) as? [String: Any])
                    let errorMsg = (json?["error"] as? [String: Any])?["message"] as? String ?? "HTTP \(statusCode)"
                    await updateTestStatus(success: false, message: "Error: \(errorMsg)")
                }
            } catch {
                await updateTestStatus(success: false, message: "Connection error: \(error.localizedDescription)")
            }
        }
    }

    private func updateTestStatus(success: Bool, message: String) async {
        await MainActor.run {
            self.isTesting = false
            self.isSuccess = success
            self.testResult = message
        }
    }
}
