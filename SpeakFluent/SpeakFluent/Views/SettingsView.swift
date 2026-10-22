import SwiftUI

public struct SettingsView: View {
    @ObservedObject public var ttsService: TextToSpeechService
    @ObservedObject public var progressViewModel: ProgressViewModel

    @State private var showingResetAlert: Bool = false

    public init(ttsService: TextToSpeechService, progressViewModel: ProgressViewModel) {
        self.ttsService = ttsService
        self.progressViewModel = progressViewModel
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Native Speaker Voice")) {
                    Picker("Voice Accent", selection: $ttsService.selectedAccent) {
                        ForEach(VoiceAccent.allCases) { accent in
                            Text("\(accent.flag) \(accent.displayName)").tag(accent)
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Playback Speed")
                            Spacer()
                            Text(String(format: "%.2fx", ttsService.speechRate / 0.5))
                                .foregroundColor(.secondary)
                        }

                        Slider(value: $ttsService.speechRate, in: 0.25...0.65, step: 0.05)
                    }

                    Button(action: {
                        ttsService.speak(text: "Hello! Welcome to SpeakFluent. Let's master English pronunciation together.")
                    }) {
                        HStack {
                            Image(systemName: "speaker.wave.2")
                            Text("Test Voice Audio")
                        }
                    }
                }

                Section(header: Text("Speech Recognition")) {
                    HStack {
                        Text("Recognition Engine")
                        Spacer()
                        Text("Apple Speech (On-Device)")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Target Language")
                        Spacer()
                        Text("English (en-US)")
                            .foregroundColor(.secondary)
                    }
                }

                Section(header: Text("Data & Progress")) {
                    Button(role: .destructive, action: {
                        showingResetAlert = true
                    }) {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Reset Practice History")
                        }
                    }
                }

                Section(header: Text("About SpeakFluent")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0 (Build 1)")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Technology")
                        Spacer()
                        Text("SwiftUI + AVFoundation + Speech")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .alert("Reset Practice Data?", isPresented: $showingResetAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Reset All", role: .destructive) {
                    progressViewModel.resetProgress()
                }
            } message: {
                Text("This will reset your current streak, average accuracy, and history. This action cannot be undone.")
            }
        }
    }
}
