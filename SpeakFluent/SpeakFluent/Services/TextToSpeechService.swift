import Foundation
import AVFoundation
import Combine

public enum VoiceAccent: String, CaseIterable, Identifiable {
    case american = "en-US"
    case british = "en-GB"
    case australian = "en-AU"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .american: return "American English (US)"
        case .british: return "British English (UK)"
        case .australian: return "Australian English (AU)"
        }
    }

    public var flag: String {
        switch self {
        case .american: return "🇺🇸"
        case .british: return "🇬🇧"
        case .australian: return "🇦🇺"
        }
    }
}

@MainActor
public final class TextToSpeechService: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    @Published public var isSpeaking: Bool = false
    @Published public var currentSpokenRange: NSRange?
    @Published public var selectedAccent: VoiceAccent = .american
    @Published public var speechRate: Float = 0.48 // Standard pleasant learner tempo

    private let synthesizer = AVSpeechSynthesizer()

    public override init() {
        super.init()
        synthesizer.delegate = self
    }

    public func speak(text: String, slow: Bool = false) {
        stop()

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .spokenAudio, options: .duckOthers)
            try session.setActive(true)
        } catch {
            print("Failed to set audio session for TTS: \(error)")
        }

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: selectedAccent.rawValue)
            ?? AVSpeechSynthesisVoice(language: "en-US")

        utterance.rate = slow ? 0.32 : speechRate
        utterance.pitchMultiplier = 1.0
        utterance.postUtteranceDelay = 0.1

        isSpeaking = true
        currentSpokenRange = nil
        synthesizer.speak(utterance)
    }

    public func speakWord(_ word: String) {
        speak(text: word, slow: true)
    }

    public func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        isSpeaking = false
        currentSpokenRange = nil
    }

    // MARK: - AVSpeechSynthesizerDelegate
    nonisolated public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, willSpeakRangeOfSpeechString characterRange: NSRange, utterance: AVSpeechUtterance) {
        Task { @MainActor [weak self] in
            self?.currentSpokenRange = characterRange
        }
    }

    nonisolated public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor [weak self] in
            self?.isSpeaking = false
            self?.currentSpokenRange = nil
        }
    }

    nonisolated public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor [weak self] in
            self?.isSpeaking = false
            self?.currentSpokenRange = nil
        }
    }
}
