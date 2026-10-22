import Foundation
import Speech
import AVFoundation
import Accelerate
import Combine

public enum SpeechRecognizerError: LocalizedError {
    case notAuthorized
    case microphoneDenied
    case speechRecognitionDenied
    case audioEngineFailed(String)
    case recognizerUnavailable

    public var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Microphone or Speech Recognition permissions have not been granted."
        case .microphoneDenied:
            return "Microphone access is denied. Please enable it in Settings to practice speaking."
        case .speechRecognitionDenied:
            return "Speech Recognition is disabled. Please enable it in Settings."
        case .audioEngineFailed(let msg):
            return "Audio Engine error: \(msg)"
        case .recognizerUnavailable:
            return "Speech recognizer is temporarily unavailable for this language."
        }
    }
}

@MainActor
public final class SpeechRecognizer: ObservableObject {
    @Published public var transcript: String = ""
    @Published public var isRecording: Bool = false
    @Published public var audioLevel: Float = 0.0
    @Published public var errorMessage: String?
    @Published public var authorizationStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined

    private var audioEngine: AVAudioEngine?
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    // Performance throttle: Avoid posting to MainActor >30 times/sec
    private var lastLevelUpdateTime: Double = 0

    public init(locale: Locale = Locale(identifier: "en-US")) {
        self.speechRecognizer = SFSpeechRecognizer(locale: locale)
        self.authorizationStatus = SFSpeechRecognizer.authorizationStatus()
    }

    public func setLocale(_ localeIdentifier: String) {
        self.speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: localeIdentifier))
    }

    public func requestPermissions() async -> Bool {
        let speechStatus = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
        self.authorizationStatus = speechStatus

        let micStatus = await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }

        return speechStatus == .authorized && micStatus
    }

    public func startRecording() throws {
        stopRecording()
        self.errorMessage = nil
        self.transcript = ""

        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            throw SpeechRecognizerError.recognizerUnavailable
        }

        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            throw SpeechRecognizerError.audioEngineFailed("Failed to setup audio session: \(error.localizedDescription)")
        }

        let engine = AVAudioEngine()
        self.audioEngine = engine

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.addsPunctuation = true
        self.recognitionRequest = request

        let inputNode = engine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        // Install audio tap: 1024 frames for ultra-low latency audio processing
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            guard let self = self else { return }
            self.recognitionRequest?.append(buffer)
            self.computeAudioLevelHardwareAccelerated(from: buffer)
        }

        self.recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self = self else { return }

            if let result = result {
                let text = result.bestTranscription.formattedString
                Task { @MainActor in
                    self.transcript = text
                }
            }

            if let error = error {
                Task { @MainActor in
                    let nsError = error as NSError
                    if nsError.domain != "kAFAssistantErrorDomain" || nsError.code != 216 {
                        self.errorMessage = error.localizedDescription
                    }
                }
            }
        }

        do {
            engine.prepare()
            try engine.start()
            self.isRecording = true
        } catch {
            stopRecording()
            throw SpeechRecognizerError.audioEngineFailed(error.localizedDescription)
        }
    }

    public func stopRecording() {
        if audioEngine?.isRunning == true {
            audioEngine?.stop()
            audioEngine?.inputNode.removeTap(onBus: 0)
        }

        recognitionRequest?.endAudio()
        recognitionTask?.cancel()

        audioEngine = nil
        recognitionRequest = nil
        recognitionTask = nil

        isRecording = false
        audioLevel = 0.0

        // Release hardware audio session to save device battery
        DispatchQueue.global(qos: .utility).async {
            try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        }
    }

    // MARK: - Hardware-Accelerated Audio Metering (Apple Accelerate SIMD)
    /// Computes RMS decibels with zero heap allocations using Apple's vDSP vector hardware
    private nonisolated func computeAudioLevelHardwareAccelerated(from buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        let frameCount = vDSP_Length(buffer.frameLength)
        guard frameCount > 0 else { return }

        // Vector Mean Square calculation in AMX/NEON hardware
        var meanSquare: Float = 0
        vDSP_measqv(channelData, 1, &meanSquare, frameCount)
        let rms = sqrt(meanSquare)
        let normalized = min(max(rms * 12.0, 0.0), 1.0)

        // Throttle UI update dispatch to ~30Hz (0.033s) to prevent main cooperative queue congestion
        let now = CACurrentMediaTime()
        guard now - lastLevelUpdateTime >= 0.033 else { return }

        Task { @MainActor in
            self.lastLevelUpdateTime = now
            self.audioLevel = (self.audioLevel * 0.4) + (normalized * 0.6)
        }
    }
}
