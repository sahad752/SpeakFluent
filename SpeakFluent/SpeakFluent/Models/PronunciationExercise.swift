import Foundation

public enum DifficultyLevel: String, CaseIterable, Identifiable, Codable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"

    public var id: String { rawValue }

    public var badgeColorName: String {
        switch self {
        case .beginner: return "green"
        case .intermediate: return "orange"
        case .advanced: return "purple"
        }
    }
}

public enum ExerciseCategory: String, CaseIterable, Identifiable, Codable {
    case dailyConversations = "Daily Chat"
    case trickySounds = "Tricky Sounds"
    case tongueTwisters = "Tongue Twisters"
    case business = "Business"
    case travel = "Travel & Food"

    public var id: String { rawValue }

    public var iconName: String {
        switch self {
        case .dailyConversations: return "bubble.left.and.bubble.right.fill"
        case .trickySounds: return "waveform.path.ecg"
        case .tongueTwisters: return "flame.fill"
        case .business: return "briefcase.fill"
        case .travel: return "airplane"
        }
    }

    public var description: String {
        switch self {
        case .dailyConversations: return "Casual everyday expressions and greetings"
        case .trickySounds: return "Master 'th', 'r/l', 'v/w', and tricky vowel contrasts"
        case .tongueTwisters: return "Sharpen articulation, speed, and muscle memory"
        case .business: return "Professional presentations and office discussions"
        case .travel: return "Ordering food, asking directions, and navigating transit"
        }
    }
}

public struct PronunciationExercise: Identifiable, Codable, Hashable {
    public let id: UUID
    public let title: String
    public let targetSentence: String
    public let phoneticIPA: String
    public let focusPhonemes: [String]
    public let tips: String
    public let difficulty: DifficultyLevel
    public let category: ExerciseCategory

    public init(
        id: UUID = UUID(),
        title: String,
        targetSentence: String,
        phoneticIPA: String,
        focusPhonemes: [String],
        tips: String,
        difficulty: DifficultyLevel,
        category: ExerciseCategory
    ) {
        self.id = id
        self.title = title
        self.targetSentence = targetSentence
        self.phoneticIPA = phoneticIPA
        self.focusPhonemes = focusPhonemes
        self.tips = tips
        self.difficulty = difficulty
        self.category = category
    }
}

// MARK: - Curated Exercises Dataset
extension PronunciationExercise {
    public static let sampleExercises: [PronunciationExercise] = [
        // Daily Conversations
        PronunciationExercise(
            title: "Morning Routine",
            targetSentence: "Could you please pass me a cup of black coffee?",
            phoneticIPA: "/kʊd juː pliːz pæs miː ə kʌp əv blæk ˈkɒfi/",
            focusPhonemes: ["/ʊ/", "/æ/", "/k/"],
            tips: "Keep 'could you' smooth like 'could-ya'. Don't stress 'of'—pronounce it softly as /əv/.",
            difficulty: .beginner,
            category: .dailyConversations
        ),
        PronunciationExercise(
            title: "Weekend Plans",
            targetSentence: "I'm really looking forward to hanging out with my friends this Saturday.",
            phoneticIPA: "/aɪm ˈrɪəli ˈlʊkɪŋ ˈfɔːwəd tuː ˈhæŋɪŋ aʊt wɪð maɪ frendz ðɪs ˈsætədeɪ/",
            focusPhonemes: ["/ŋ/", "/ð/", "/æ/"],
            tips: "Ensure 'forward' has a clear first syllable stress, and don't omit the 'g' in 'hanging'.",
            difficulty: .intermediate,
            category: .dailyConversations
        ),
        PronunciationExercise(
            title: "Polite Request",
            targetSentence: "Would you mind if I opened the window for some fresh air?",
            phoneticIPA: "/wʊd juː maɪnd ɪf aɪ ˈəʊpənd ðə ˈwɪndəʊ fɔː sʌm freʃ eə/",
            focusPhonemes: ["/w/", "/ð/", "/ʃ/"],
            tips: "Blend 'mind if I' into a continuous flow: 'mind-if-I'.",
            difficulty: .beginner,
            category: .dailyConversations
        ),

        // Tricky Sounds
        PronunciationExercise(
            title: "Voiced vs Voiceless TH",
            targetSentence: "They think that their thirty brothers are trustworthy.",
            phoneticIPA: "/ðeɪ θɪŋk ðæt ðeə ˈθɜːti ˈbrʌðəz ɑː ˈtrʌstˌwɜːði/",
            focusPhonemes: ["/θ/", "/ð/"],
            tips: "Place the tip of your tongue gently between your front teeth. 'They/that' are voiced (vibrating cords); 'think/thirty' are voiceless air.",
            difficulty: .intermediate,
            category: .trickySounds
        ),
        PronunciationExercise(
            title: "R and L Contrast",
            targetSentence: "Really lovely red roses line the long river railway.",
            phoneticIPA: "/ˈrɪəli ˈlʌvli red ˈrəʊzɪz laɪn ðə lɒŋ ˈrɪvə ˈreɪlweɪ/",
            focusPhonemes: ["/r/", "/l/"],
            tips: "For /l/, press the tongue tip behind top teeth. For /r/, curl the tongue back without touching the roof of the mouth.",
            difficulty: .intermediate,
            category: .trickySounds
        ),
        PronunciationExercise(
            title: "V and W Distinction",
            targetSentence: "We went viewing vintage velvet wagons in the West Village.",
            phoneticIPA: "/wiː went ˈvjuːɪŋ ˈvɪntɪdʒ ˈvelvɪt ˈwæɡənz ɪn ðə west ˈvɪlɪdʒ/",
            focusPhonemes: ["/v/", "/w/"],
            tips: "Touch top teeth to lower lip for 'V' (/v/). Round your lips into a tight circle for 'W' (/w/).",
            difficulty: .advanced,
            category: .trickySounds
        ),

        // Tongue Twisters
        PronunciationExercise(
            title: "Peter Piper",
            targetSentence: "Peter Piper picked a peck of pickled peppers.",
            phoneticIPA: "/ˈpiːtə ˈpaɪpə pɪkt ə pek əv ˈpɪkəld ˈpepəz/",
            focusPhonemes: ["/p/", "/t/", "/k/"],
            tips: "Focus on crisp plosive /p/ sounds with short bursts of air.",
            difficulty: .intermediate,
            category: .tongueTwisters
        ),
        PronunciationExercise(
            title: "Seashore Shells",
            targetSentence: "She sells seashells by the seashore, and the shells she sells are surely seashells.",
            phoneticIPA: "/ʃiː selz ˈsiːʃelz baɪ ðə ˈsiːʃɔː ænd ðə ʃelz ʃiː selz ɑː ˈʃʊəli ˈsiːʃelz/",
            focusPhonemes: ["/s/", "/ʃ/"],
            tips: "Alternate sharply between the hissing /s/ and the rushing /ʃ/ sound without blending them.",
            difficulty: .advanced,
            category: .tongueTwisters
        ),

        // Business
        PronunciationExercise(
            title: "Project Milestone",
            targetSentence: "Our primary objective is to streamline quarterly operations and maximize productivity.",
            phoneticIPA: "/ˈaʊə ˈpraɪməri əbˈdʒektɪv ɪz tuː ˈstriːmlaɪn ˈkwɔːtəli ˌɒpəˈreɪʃənz ænd ˈmæksɪmaɪz ˌprɒdʌkˈtɪvəti/",
            focusPhonemes: ["/kw/", "/str/", "/dʒ/"],
            tips: "Emphasize key nouns: 'objective', 'streamline', and 'productivity'.",
            difficulty: .advanced,
            category: .business
        ),
        PronunciationExercise(
            title: "Meeting Opening",
            targetSentence: "Thank you all for joining today's strategy alignment meeting.",
            phoneticIPA: "/θæŋk juː ɔːl fɔː ˈdʒɔɪnɪŋ təˈdeɪz ˈstrætədʒi əˈlaɪnmənt ˈmiːtɪŋ/",
            focusPhonemes: ["/θ/", "/dʒ/", "/str/"],
            tips: "Start strong with an open /θæŋk/ sound and articulate the ending of 'alignment'.",
            difficulty: .beginner,
            category: .business
        ),

        // Travel
        PronunciationExercise(
            title: "Airport Check-in",
            targetSentence: "Excuse me, where can I find baggage claim for international arrivals?",
            phoneticIPA: "/ɪkˈskjuːz miː weə kæn aɪ faɪnd ˈbæɡɪdʒ kleɪm fɔːr ˌɪntəˈnæʃnəl əˈraɪvəlz/",
            focusPhonemes: ["/skj/", "/dʒ/", "/ʃ/"],
            tips: "Link 'where can I' cleanly and finish with a slight rising inflection for the question.",
            difficulty: .intermediate,
            category: .travel
        ),
        PronunciationExercise(
            title: "Ordering at a Restaurant",
            targetSentence: "Could we have the chef's special with roasted vegetables and sparkling water?",
            phoneticIPA: "/kʊd wiː hæv ðə ʃefs ˈspeʃəl wɪð ˈrəʊstɪd ˈvedʒtəblz ænd ˈspɑːklɪŋ ˈwɔːtə/",
            focusPhonemes: ["/ʃ/", "/sp/", "/v/"],
            tips: "Notice 'vegetables' is typically pronounced in 3 syllables: 'vege-ta-bles' (/ˈvedʒtəblz/).",
            difficulty: .beginner,
            category: .travel
        )
    ]
}
