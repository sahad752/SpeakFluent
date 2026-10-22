import Foundation

public struct LLMConfig {
    public static let shared = LLMConfig()

    private let userDefaultsKey = "com.speakfluent.gemini_api_key"
    private let customEndpointKey = "com.speakfluent.custom_llm_endpoint"
    private let useMockKey = "com.speakfluent.use_mock_llm"

    public var apiKey: String {
        get {
            UserDefaults.standard.string(forKey: userDefaultsKey) ?? ""
        }
        set {
            UserDefaults.standard.set(newValue, forKey: userDefaultsKey)
        }
    }

    public var customEndpoint: String {
        get {
            UserDefaults.standard.string(forKey: customEndpointKey) ?? "https://generativelanguage.googleapis.com/v1beta"
        }
        set {
            UserDefaults.standard.set(newValue, forKey: customEndpointKey)
        }
    }

    public var modelName: String = "gemini-1.5-flash"

    public var isMockModeEnabled: Bool {
        get {
            // If no API key is provided, gracefully default to local realistic LLM simulation
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
