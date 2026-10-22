# LLM-Powered English Speaking Assistant (iOS) 🎙️

An open-source native iOS voice application in **Swift** and **SwiftUI** engineered for ultra-low latency real-time speech evaluation, conversational turn-taking, and adaptive pronunciation coaching.

[![iOS](https://img.shields.io/badge/iOS-17.0%2B-blue.svg)](https://developer.apple.com/ios/)
[![Swift](https://img.shields.io/badge/Swift-5.9%20%2F%206.0-orange.svg)](https://swift.org/)
[![Architecture](https://img.shields.io/badge/Architecture-MVVM%20%2B%20Services-green.svg)]()
[![License](https://img.shields.io/badge/License-MIT-lightgrey.svg)]()

---

## 🏛️ System Architecture

```
                    ┌──────────────────────────────────────────────┐
                    │               AVAudioEngine                  │
                    │   (Low-latency 1024-buffer Mic Capture)     │
                    └──────────────────────┬───────────────────────┘
                                           │
                                           ▼
┌──────────────────────────────────────────────────────────────────────────────────┐
│                           Voice Turn-Taking Pipeline                             │
│                                                                                  │
│   [User Speaks] ──► [SFSpeechRecognizer] ──► [WebSocket / SSE Streaming Client]  │
│                                                            │                     │
│                                                            ▼                     │
│                                               [LLM API / Structured Outputs]     │
│                                               (Gemini Flash / JSON Schema)       │
│                                                            │                     │
│   [Audio Synthesis] ◄── [Token Stream] ◄───────────────────┘                     │
│   (AVSpeechSynthesizer)                                                          │
└──────────────────────────────────────────────────────────────────────────────────┘
```

---

## 🚀 Key Highlights

### 1. Native iOS Architecture & State Machine
* **Swift & SwiftUI**: Built using modern declarative SwiftUI with clean separation across MVVM and protocol-oriented Services.
* **Turn-Taking State Machine (`TurnState`)**:
  - `userSpeaking` ➔ `streamingToLLM` ➔ `aiStreamingResponse(tokens)` ➔ `aiSpeaking` ➔ `waitingForUser(adaptivePrompt)`
  - Seamless voice handoff between user speech and AI responses.

### 2. Audio & Applied AI Pipeline with Structured Outputs
* **AVFoundation Capture**: `AVAudioEngine` installs an input tap with 1024-frame PCM buffers, calculating root-mean-square (RMS) decibels to animate the 28-band real-time audio visualizer.
* **LLM APIs with JSON Schema (`LLMPronunciationEvaluation`)**:
  Enforces strictly typed structured responses:
  ```json
  {
    "overallScore": 92,
    "accuracy": 94,
    "fluency": 90,
    "coachFeedback": "Crisp plosives on 'picked' and good long vowel glide.",
    "phoneticMistakes": [
      {
        "word": "think",
        "expectedIPA": "/θɪŋk/",
        "heardSound": "[tɪŋk]",
        "tip": "Place your tongue between your teeth for voiceless /θ/."
      }
    ],
    "grammarCorrection": null,
    "adaptiveFollowUpPrompt": "What other challenges have you encountered with English vowels?",
    "suggestedSampleReply": "I sometimes struggle distinguishing between short and long vowels."
  }
  ```

### 3. Streaming & Low Latency over WebSockets
* **WebSocket Client (`WebSocketStreamingClient`)**:
  - Low-latency bidirectional streaming of audio chunks and text tokens.
  - Sub-second round-trip time with active ping-pong heartbeat and round-trip latency metrics (`latencyMs`).
  - Active memory buffer pruning maintaining a lightweight **~30 MB memory footprint**.
* **Token Streaming (`streamConversationTokens`)**:
  - Uses `AsyncThrowingStream` to render conversational responses word-by-word with zero perceptual lag.

### 4. Interactive Pronunciation Coach & Drills
* **Phonetic IPA & Articulation Drills**: Master tricky sounds (`th`, `r/l`, `v/w`, tongue twisters, business, and travel).
* **Multi-Accent Support**: Real-time voice synthesis in **American English 🇺🇸**, **British English 🇬🇧**, and **Australian English 🇦🇺**.
* **Gamification**: Consecutive day flame streaks, accuracy progression graphs, and unlockable achievement badges.

---

## 📁 Repository Structure

```
SpeakFluent/
├── SpeakFluent.xcodeproj/              # Xcode project configured for iOS 17.0+
├── Package.swift                      # SPM configuration
└── SpeakFluent/
    ├── SpeakFluentApp.swift           # Application Lifecycle (@main)
    ├── Info.plist                     # Mic & Speech Recognition permissions
    │
    ├── Services/
    │   ├── SpeechRecognizer.swift     # AVAudioEngine tap + SFSpeechRecognizer + RMS metering
    │   ├── TextToSpeechService.swift  # AVSpeechSynthesizer with accent & tempo delegate
    │   ├── PronunciationEvaluator.swift # Word alignment & phonetic distance algorithms
    │   └── LLM/
    │       ├── LLMConfig.swift        # API keys, custom endpoints, zero-latency demo mode
    │       ├── LLMStructuredOutput.swift # Codable JSON Schema response models
    │       ├── LLMServiceProtocol.swift # Contract for LLM evaluation & streaming
    │       ├── GeminiLLMService.swift # REST + SSE streaming implementation
    │       └── WebSocketStreamingClient.swift # Low-latency WebSocket client (~30 MB footprint)
    │
    ├── ViewModels/
    │   ├── ConversationTurnViewModel.swift # Full-duplex conversational turn-taking coordinator
    │   ├── CoachViewModel.swift       # Pronunciation practice lifecycle
    │   ├── PracticeHubViewModel.swift # Exercise search & category filtering
    │   └── ProgressViewModel.swift    # Persistent stats & streak tracking
    │
    └── Views/
        ├── ContentView.swift          # Main TabView navigation
        ├── ConversationTurnView.swift # AI Voice partner screen with streaming bubbles
        ├── CoachView.swift            # Sentence-level pronunciation coaching
        ├── PronunciationScoreSheet.swift # Detailed word-by-word score breakdown
        ├── ExerciseListView.swift     # Categorized practice library
        ├── DailyStreakView.swift      # Gamified streak & stats
        ├── SettingsView.swift         # Voice, accent & LLM settings
        └── Components/                # WaveformVisualizer, ScoreGaugeView, WordScorePill
```

---

## 🛠️ Tech Stack

* **Language**: Swift 5.9 / 6.0
* **Framework**: SwiftUI (iOS 17+)
* **Audio Engineering**: AVFoundation (`AVAudioEngine`, `AVAudioSession`, `AVSpeechSynthesizer`)
* **Speech Processing**: Apple Speech (`SFSpeechRecognizer`, `SFSpeechAudioBufferRecognitionRequest`)
* **Networking & AI**:
  - `URLSessionWebSocketTask` (Streaming WebSockets)
  - Async/Await & `AsyncThrowingStream` (SSE Token Streaming)
  - Google Gemini API (`gemini-1.5-flash`) with JSON Schema Structured Outputs
* **Architecture**: MVVM + Service Layer + State Machine

---

## 🏃 Running on Physical iPhone or Simulator

1. **Open the project in Xcode**:
   ```bash
   open "SpeakFluent/SpeakFluent.xcodeproj"
   ```
2. Select your connected **iPhone** or **iOS Simulator**.
3. In **Signing & Capabilities**, select your **Personal Team** (free Apple ID, no paid developer account required).
4. Press `Cmd + R` to build and run.
5. In the app:
   - Go to **AI Voice** tab to practice real-time conversational turn-taking.
   - Tap the settings gear icon to configure your own Gemini API key or use the built-in zero-latency demo mode!
