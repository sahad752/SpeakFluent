import Foundation

public struct PronunciationEvaluator {

    public static func evaluate(
        targetSentence: String,
        transcribedSentence: String,
        exercise: PronunciationExercise?
    ) -> SpeechAnalysisResult {
        let cleanTargetWords = tokenize(sentence: targetSentence)
        let cleanSpokenWords = tokenize(sentence: transcribedSentence)

        var wordAnalyses: [WordAnalysis] = []
        wordAnalyses.reserveCapacity(cleanTargetWords.count)
        var totalWordScore: Double = 0.0

        for (index, targetWord) in cleanTargetWords.enumerated() {
            let normalizedTarget = targetWord.lowercased()

            let spokenMatch = findBestSpokenWord(
                target: normalizedTarget,
                targetIndex: index,
                spokenTokens: cleanSpokenWords
            )

            let score: Double
            let status: WordAccuracyStatus
            let feedback: String

            if let spoken = spokenMatch {
                let similarity = stringSimilarity(s1: normalizedTarget, s2: spoken.lowercased())
                score = round(similarity * 100.0)

                if score >= 90.0 {
                    status = .perfect
                    feedback = "Spot on! Crisp and native-sounding pronunciation."
                } else if score >= 75.0 {
                    status = .good
                    feedback = "Understood clearly, with slight accent or vowel drift."
                } else if score >= 45.0 {
                    status = .needsWork
                    feedback = generatePhoneticFeedback(target: normalizedTarget, spoken: spoken)
                } else {
                    status = .missed
                    feedback = "Heard as '\(spoken)'. Try slowing down this syllable."
                }
            } else {
                score = 0.0
                status = .missed
                feedback = "Word was skipped or not caught by the microphone."
            }

            totalWordScore += score

            wordAnalyses.append(
                WordAnalysis(
                    targetWord: targetWord,
                    spokenWord: spokenMatch,
                    score: score,
                    status: status,
                    feedback: feedback,
                    phoneticHint: nil
                )
            )
        }

        let accuracy = cleanTargetWords.isEmpty ? 0 : Int(round(totalWordScore / Double(cleanTargetWords.count)))
        let completenessRatio = Double(cleanSpokenWords.count) / Double(max(cleanTargetWords.count, 1))
        let completeness = min(100, Int(round(min(completenessRatio, 1.0) * 100.0)))
        let fluency = Int(round(Double(accuracy) * 0.7 + Double(completeness) * 0.3))
        let overall = Int(round(Double(accuracy) * 0.6 + Double(completeness) * 0.25 + Double(fluency) * 0.15))

        let coachTip = generateCoachTip(
            overallScore: overall,
            accuracy: accuracy,
            analyses: wordAnalyses,
            exercise: exercise
        )

        return SpeechAnalysisResult(
            targetSentence: targetSentence,
            transcribedSentence: transcribedSentence,
            overallScore: overall,
            pronunciationAccuracy: accuracy,
            fluencyScore: fluency,
            completenessScore: completeness,
            words: wordAnalyses,
            coachTip: coachTip
        )
    }

    // MARK: - Tokenization
    private static func tokenize(sentence: String) -> [String] {
        let punctuation = CharacterSet.punctuationCharacters
        return sentence
            .components(separatedBy: .whitespacesAndNewlines)
            .map { $0.trimmingCharacters(in: punctuation) }
            .filter { !$0.isEmpty }
    }

    // MARK: - Word Alignment & Distance
    private static func findBestSpokenWord(target: String, targetIndex: Int, spokenTokens: [String]) -> String? {
        guard !spokenTokens.isEmpty else { return nil }

        let window = 2
        let lowerBound = max(0, targetIndex - window)
        let upperBound = min(spokenTokens.count - 1, targetIndex + window)

        var bestMatch: String? = nil
        var bestScore: Double = -1.0

        for i in lowerBound...upperBound {
            let candidate = spokenTokens[i]
            let sim = stringSimilarity(s1: target, s2: candidate.lowercased())
            if sim > bestScore {
                bestScore = sim
                bestMatch = candidate
            }
        }

        if bestScore < 0.45 {
            for candidate in spokenTokens {
                let sim = stringSimilarity(s1: target, s2: candidate.lowercased())
                if sim > bestScore && sim > 0.6 {
                    bestScore = sim
                    bestMatch = candidate
                }
            }
        }

        return bestScore >= 0.35 ? bestMatch : nil
    }

    // MARK: - Space-Optimized O(N) Levenshtein Distance
    /// Uses two flat 1D row buffers instead of an (M x N) 2D heap matrix
    public static func stringSimilarity(s1: String, s2: String) -> Double {
        if s1 == s2 { return 1.0 }
        if s1.isEmpty || s2.isEmpty { return 0.0 }

        let str1 = Array(s1)
        let str2 = Array(s2)
        let m = str1.count
        let n = str2.count

        var previousRow = [Int](0...n)
        var currentRow = [Int](repeating: 0, count: n + 1)

        for i in 1...m {
            currentRow[0] = i
            let char1 = str1[i - 1]

            for j in 1...n {
                let cost = (char1 == str2[j - 1]) ? 0 : 1
                currentRow[j] = min(
                    previousRow[j] + 1,       // deletion
                    currentRow[j - 1] + 1,     // insertion
                    previousRow[j - 1] + cost  // substitution
                )
            }
            previousRow = currentRow
        }

        let distance = Double(previousRow[n])
        let maxLen = Double(max(m, n))
        return max(0.0, 1.0 - (distance / maxLen))
    }

    private static func generatePhoneticFeedback(target: String, spoken: String) -> String {
        if target.contains("th") && !spoken.contains("th") {
            return "Mind the 'th' sound: lightly touch your tongue to your front teeth."
        }
        if target.contains("r") && spoken.contains("l") {
            return "Watch the 'r' vs 'l' contrast: don't let tongue touch palate for 'r'."
        }
        if target.contains("v") && spoken.contains("w") {
            return "Distinguish 'v' and 'w': rest upper teeth on lower lip for 'v'."
        }
        return "Heard as '\(spoken)'. Pronounce clearly without dropping end consonants."
    }

    private static func generateCoachTip(
        overallScore: Int,
        accuracy: Int,
        analyses: [WordAnalysis],
        exercise: PronunciationExercise?
    ) -> String {
        if overallScore >= 92 {
            return "Exceptional job! Your pronunciation is clear, fluent, and effortlessly understood."
        } else if overallScore >= 80 {
            if let exerciseTip = exercise?.tips {
                return "Good performance! Coach tip: \(exerciseTip)"
            }
            return "Good flow! Practice holding long vowels and softening unstressed articles."
        } else if overallScore >= 65 {
            let strugglingWords = analyses.filter { $0.status == .needsWork || $0.status == .missed }.map { $0.targetWord }
            if !strugglingWords.isEmpty {
                let sample = strugglingWords.prefix(2).joined(separator: ", ")
                return "You're getting there! Tap on '\(sample)' to hear the native pronunciation breakdown."
            }
            return "Focus on steady pacing. Listen to the native audio once more and repeat in rhythm."
        } else {
            return "Take a deep breath and listen carefully to the native speaker before speaking again. Quality over speed!"
        }
    }
}
