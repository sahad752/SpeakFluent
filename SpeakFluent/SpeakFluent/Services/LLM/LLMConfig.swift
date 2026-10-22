import Foundation

public struct LLMConfig {
    public static var shared = LLMConfig()

    private let userDefaultsKey = "com.speakfluent.gemini_api_key"
    private let customEndpointKey = "com.speakfluent.custom_llm_endpoint"
    private let modelNameKey = "com.speakfluent.gemini_model_name"
    private let useMockKey = "com.speakfluent.use_mock_llm"

    public var apiKey: String {
        get {
            UserDefaults.standard.string(forKey: userDefaultsKey) ?? ""
        }
        set {
            UserDefaults.standard.set(newValue.trimmingCharacters(in: .whitespacesAndNewlines), forKey: userDefaultsKey)
        }
    }

    public var customEndpoint: String {
        get {
            UserDefaults.standard.string(forKey: customEndpointKey) ?? "https://generativelanguage.googleapis.com/v1beta"
        }
        set {
            UserDefaults.standard.set(newValue.trimmingCharacters(in: .whitespacesAndNewlines), forKey: customEndpointKey)
        }
    }

    public var modelName: String {
        get {
            UserDefaults.standard.string(forKey: modelNameKey) ?? "gemini-2.5-flash"
        }
        set {
            let cleaned = newValue.hasPrefix("models/") ? String(newValue.dropFirst(7)) : newValue
            UserDefaults.standard.set(cleaned, forKey: modelNameKey)
        }
    }

    public var cleanModelName: String {
        modelName.hasPrefix("models/") ? String(modelName.dropFirst(7)) : modelName
    }

    public var isMockModeEnabled: Bool {
        get {
            if apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return true
            }
            return UserDefaults.standard.bool(forKey: useMockKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: useMockKey)
        }
    }

    public static let systemInstruction = """
    You are an expert, empathetic, native English pronunciation and speaking coach.
    Your goal is to converse with English learners, evaluate their spoken clarity, provide constructive phonetic feedback on mispronounced words, correct any major grammatical errors gently, and keep the dialogue flowing naturally with an adaptive follow-up prompt.
    Always format your analysis matching the provided structured JSON schema.
    """
}
