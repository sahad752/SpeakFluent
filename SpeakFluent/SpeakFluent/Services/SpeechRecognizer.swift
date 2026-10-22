import Foundation
import Speech
import AVFoundation
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
    @Published public var audioLevel: Float = 0.0 // 0.0 to 1.0 normalized
    @Published public var errorMessage: String?
    @Published public var authorizationStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined

    private var audioEngine: AVAudioEngine?
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

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
        // Cancel ongoing tasks if any
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

        // Install audio tap to stream buffers and calculate audio levels
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
            self?.computeAudioLevel(from: buffer)
        }

        self.recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self = self else { return }

            if let result = result {
                Task { @MainActor in
                    self.transcript = result.bestTranscription.formattedString
                }
            }

            if let error = error {
                Task { @MainActor in
                    // Only surface unexpected errors (not intentional cancellation)
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

        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    private func computeAudioLevel(from buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        let channelDataArray = Array(UnsafeBufferPointer(start: channelData, count: Int(buffer.frameLength)))

        var sumSquares: Float = 0
        for sample in channelDataArray {
            sumSquares += sample * sample
        }
        let rms = sqrt(sumSquares / Float(buffer.frameLength))
        // Normalize RMS roughly to 0.0 ... 1.0
        let normalized = min(max(rms * 12.0, 0.0), 1.0)

        Task { @MainActor in
            // Smooth meter transition
            self.audioLevel = (self.audioLevel * 0.4) + (normalized * 0.6)
        }
    }
}
