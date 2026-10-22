import SwiftUI

public struct CoachView: View {
    @ObservedObject public var viewModel: CoachViewModel
    @ObservedObject public var progressViewModel: ProgressViewModel

    @State private var isShowingTips: Bool = false
    @State private var pulsingAnimation: Bool = false

    public init(viewModel: CoachViewModel, progressViewModel: ProgressViewModel) {
        self.viewModel = viewModel
        self.progressViewModel = progressViewModel
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Category & Difficulty Bar
                        headerBar

                        // Target Sentence Card
                        targetSentenceCard

                        // Phonetic & Pronunciation Guidance
                        phoneticsCard

                        // Live Waveform Visualizer
                        WaveformVisualizer(
                            levels: viewModel.audioLevelsHistory,
                            isRecording: viewModel.state == .listening
                        )

                        // Real-time Recognized Speech Display
                        liveTranscriptBox

                        // Permission or Error Alert if any
                        if case .permissionNeeded = viewModel.state {
                            permissionWarningView
                        }

                        if case .error(let msg) = viewModel.state {
                            errorBanner(message: msg)
                        }

                        Spacer(minLength: 20)

                        // Big Tactical Microphone Button
                        micControlSection
                            .padding(.bottom, 24)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                }
            }
            .navigationTitle("Pronunciation Coach")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        viewModel.nextExercise()
                    }) {
                        HStack(spacing: 4) {
                            Text("Next")
                            Image(systemName: "forward.fill")
                        }
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    }
                }
            }
            .sheet(isPresented: $viewModel.showScoreSheet) {
                if let result = viewModel.latestResult {
                    PronunciationScoreSheet(
                        result: result,
                        onRetry: {
                            viewModel.retryExercise()
                        },
                        onNext: {
                            viewModel.nextExercise()
                        },
                        onPlayWordAudio: { word in
                            viewModel.playWordAudio(word)
                        }
                    )
                    .onAppear {
                        progressViewModel.recordSession(result: result)
                    }
                }
            }
        }
    }

    // MARK: - Subviews
    private var headerBar: some View {
        HStack {
            HStack(spacing: 6) {
                Image(systemName: viewModel.currentExercise.category.iconName)
                    .foregroundColor(.blue)
                Text(viewModel.currentExercise.category.rawValue)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.blue.opacity(0.12))
            .cornerRadius(8)

            Spacer()

            Text(viewModel.currentExercise.difficulty.rawValue)
                .font(.caption)
                .fontWeight(.bold)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(difficultyColor.opacity(0.15))
                .foregroundColor(difficultyColor)
                .cornerRadius(8)
        }
    }

    private var targetSentenceCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(viewModel.currentExercise.title)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                    .tracking(1.0)

                Spacer()

                // Slow Speed Toggle
                Button(action: {
                    viewModel.isSlowPlayback.toggle()
                }) {
                    HStack(spacing: 3) {
                        Image(systemName: "tortoise.fill")
                            .font(.caption)
                        Text(viewModel.isSlowPlayback ? "Slow" : "Normal")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(viewModel.isSlowPlayback ? Color.orange.opacity(0.18) : Color.gray.opacity(0.12))
                    .foregroundColor(viewModel.isSlowPlayback ? .orange : .secondary)
                    .cornerRadius(8)
                }

                // Native Audio Play Button
                Button(action: {
                    viewModel.playNativeAudio()
                }) {
                    Image(systemName: viewModel.ttsService.isSpeaking ? "stop.circle.fill" : "speaker.wave.2.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.blue)
                }
            }

            Text(viewModel.currentExercise.targetSentence)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .lineSpacing(4)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(UIColor.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.gray.opacity(0.12), lineWidth: 1)
        )
    }

    private var phoneticsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(viewModel.currentExercise.phoneticIPA)
                    .font(.system(size: 15, weight: .medium, design: .monospaced))
                    .foregroundColor(.indigo)

                Spacer()

                Button(action: {
                    withAnimation { isShowingTips.toggle() }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "lightbulb.fill")
                            .font(.caption)
                        Text(isShowingTips ? "Hide Tips" : "Tips")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.secondary)
                }
            }

            // Focus phonemes tags
            HStack(spacing: 6) {
                Text("Focus:")
                    .font(.caption)
                    .foregroundColor(.secondary)

                ForEach(viewModel.currentExercise.focusPhonemes, id: \.self) { phoneme in
                    Text(phoneme)
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.indigo.opacity(0.12))
                        .foregroundColor(.indigo)
                        .cornerRadius(6)
                }
            }

            if isShowingTips {
                Divider()
                Text(viewModel.currentExercise.tips)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineSpacing(3)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemBackground).opacity(0.7))
        )
    }

    private var liveTranscriptBox: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Circle()
                    .fill(viewModel.state == .listening ? Color.red : Color.gray.opacity(0.4))
                    .frame(width: 8, height: 8)

                Text(viewModel.state == .listening ? "Listening to your voice..." : "Spoken transcription")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }

            Text(viewModel.liveTranscript.isEmpty ? "Tap the mic and speak the sentence aloud." : viewModel.liveTranscript)
                .font(.system(.body, design: .rounded))
                .foregroundColor(viewModel.liveTranscript.isEmpty ? .secondary : .primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(minHeight: 48)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemBackground))
        )
    }

    private var micControlSection: some View {
        VStack(spacing: 12) {
            ZStack {
                // Pulsing outer aura while recording
                if viewModel.state == .listening {
                    Circle()
                        .stroke(Color.red.opacity(0.35), lineWidth: 10)
                        .frame(width: 100, height: 100)
                        .scaleEffect(pulsingAnimation ? 1.25 : 1.0)
                        .opacity(pulsingAnimation ? 0.0 : 1.0)
                        .onAppear {
                            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: false)) {
                                pulsingAnimation = true
                            }
                        }
                        .onDisappear {
                            pulsingAnimation = false
                        }
                }

                Button(action: {
                    viewModel.toggleRecording()
                }) {
                    ZStack {
                        Circle()
                            .fill(
                                viewModel.state == .listening
                                    ? LinearGradient(colors: [.red, .pink], startPoint: .topLeading, endPoint: .bottomTrailing)
                                    : LinearGradient(colors: [.blue, .indigo], startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                            .frame(width: 80, height: 80)
                            .shadow(
                                color: viewModel.state == .listening ? Color.red.opacity(0.5) : Color.blue.opacity(0.4),
                                radius: 14,
                                x: 0,
                                y: 6
                            )

                        if viewModel.state == .evaluating {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.3)
                        } else {
                            Image(systemName: viewModel.state == .listening ? "stop.fill" : "mic.fill")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                }
                .disabled(viewModel.state == .evaluating)
            }

            Text(micButtonHint)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
        }
    }

    private var micButtonHint: String {
        switch viewModel.state {
        case .idle:
            return "Tap to Start Speaking"
        case .listening:
            return "Tap when Finished Speaking"
        case .evaluating:
            return "Analyzing Pronunciation..."
        case .resultReady:
            return "Tap to Practice Again"
        case .permissionNeeded:
            return "Microphone Access Required"
        case .error:
            return "Tap to Retry"
        }
    }

    private var difficultyColor: Color {
        switch viewModel.currentExercise.difficulty {
        case .beginner: return .green
        case .intermediate: return .orange
        case .advanced: return .purple
        }
    }

    private var permissionWarningView: some View {
        VStack(spacing: 8) {
            Image(systemName: "mic.slash.fill")
                .foregroundColor(.red)
            Text("Microphone or Speech Recognition Permission Required")
                .font(.headline)
            Text("Please enable Microphone and Speech Recognition in your iPhone Settings to analyze pronunciation.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(16)
        .background(Color.red.opacity(0.1))
        .cornerRadius(12)
    }

    private func errorBanner(message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
            Text(message)
                .font(.caption)
                .foregroundColor(.primary)
            Spacer()
        }
        .padding(12)
        .background(Color.orange.opacity(0.12))
        .cornerRadius(10)
    }
}
