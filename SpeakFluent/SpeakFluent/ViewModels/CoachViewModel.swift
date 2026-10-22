import Foundation
import SwiftUI
import Combine

public enum CoachState: Equatable {
    case idle
    case listening
    case evaluating
    case resultReady(SpeechAnalysisResult)
    case permissionNeeded
    case error(String)

    public static func == (lhs: CoachState, rhs: CoachState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.listening, .listening), (.evaluating, .evaluating), (.permissionNeeded, .permissionNeeded):
            return true
        case (.resultReady(let r1), .resultReady(let r2)):
            return r1.id == r2.id
        case (.error(let e1), .error(let e2)):
            return e1 == e2
        default:
            return false
        }
    }
}

@MainActor
public final class CoachViewModel: ObservableObject {
    @Published public var currentExercise: PronunciationExercise
    @Published public var state: CoachState = .idle
    @Published public var liveTranscript: String = ""
    @Published public var audioPower: Float = 0.0
    @Published public var audioLevelsHistory: [CGFloat] = Array(repeating: 0.15, count: 28)
    @Published public var latestResult: SpeechAnalysisResult?
    @Published public var isSlowPlayback: Bool = false
    @Published public var showScoreSheet: Bool = false
    @Published public var selectedWordForDetails: WordAnalysis?

    public let speechRecognizer: SpeechRecognizer
    public let ttsService: TextToSpeechService
    private var cancellables = Set<AnyCancellable>()

    public init(
        initialExercise: PronunciationExercise = PronunciationExercise.sampleExercises[0],
        speechRecognizer: SpeechRecognizer? = nil,
        ttsService: TextToSpeechService? = nil
    ) {
        self.currentExercise = initialExercise
        self.speechRecognizer = speechRecognizer ?? SpeechRecognizer()
        self.ttsService = ttsService ?? TextToSpeechService()

        bindRecognizer()
    }

    private func bindRecognizer() {
        speechRecognizer.$transcript
            .receive(on: DispatchQueue.main)
            .sink { [weak self] transcript in
                guard let self = self else { return }
                self.liveTranscript = transcript
            }
            .store(in: &cancellables)

        speechRecognizer.$audioLevel
            .receive(on: DispatchQueue.main)
            .sink { [weak self] level in
                guard let self = self else { return }
                self.audioPower = level
                if self.state == .listening {
                    // Update rolling audio waveform history
                    var updated = self.audioLevelsHistory
                    updated.removeFirst()
                    let normalizedLevel = CGFloat(max(0.12, min(Double(level), 1.0)))
                    updated.append(normalizedLevel)
                    self.audioLevelsHistory = updated
                }
            }
            .store(in: &cancellables)

        speechRecognizer.$errorMessage
            .receive(on: DispatchQueue.main)
            .compactMap { $0 }
            .sink { [weak self] errorMsg in
                self?.state = .error(errorMsg)
            }
            .store(in: &cancellables)
    }

    public func setExercise(_ exercise: PronunciationExercise) {
        stopAll()
        self.currentExercise = exercise
        self.state = .idle
        self.latestResult = nil
        self.liveTranscript = ""
        self.showScoreSheet = false
    }

    public func playNativeAudio() {
        if ttsService.isSpeaking {
            ttsService.stop()
        } else {
            ttsService.speak(text: currentExercise.targetSentence, slow: isSlowPlayback)
        }
    }

    public func playWordAudio(_ word: String) {
        let cleanWord = word.trimmingCharacters(in: .punctuationCharacters)
        ttsService.speakWord(cleanWord)
    }

    public func toggleRecording() {
        if state == .listening {
            finishAndEvaluate()
        } else {
            Task {
                await startRecording()
            }
        }
    }

    public func startRecording() async {
        stopAll()

        let granted = await speechRecognizer.requestPermissions()
        guard granted else {
            state = .permissionNeeded
            return
        }

        do {
            try speechRecognizer.startRecording()
            state = .listening
            liveTranscript = ""
            audioLevelsHistory = Array(repeating: 0.15, count: 28)
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    public func finishAndEvaluate() {
        guard state == .listening else { return }
        state = .evaluating
        speechRecognizer.stopRecording()

        let transcript = self.liveTranscript
        let exercise = self.currentExercise

        // Brief delay for tactile satisfaction & async evaluation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            guard let self = self else { return }
            let result = PronunciationEvaluator.evaluate(
                targetSentence: exercise.targetSentence,
                transcribedSentence: transcript,
                exercise: exercise
            )
            self.latestResult = result
            self.state = .resultReady(result)
            self.showScoreSheet = true
        }
    }

    public func retryExercise() {
        stopAll()
        self.state = .idle
        self.latestResult = nil
        self.liveTranscript = ""
        self.showScoreSheet = false
    }

    public func nextExercise() {
        let all = PronunciationExercise.sampleExercises
        if let idx = all.firstIndex(where: { $0.id == currentExercise.id }), idx + 1 < all.count {
            setExercise(all[idx + 1])
        } else if let first = all.first {
            setExercise(first)
        }
    }

    public func stopAll() {
        speechRecognizer.stopRecording()
        ttsService.stop()
    }
}
