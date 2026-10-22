import SwiftUI

public struct PronunciationScoreSheet: View {
    public let result: SpeechAnalysisResult
    public let onRetry: () -> Void
    public let onNext: () -> Void
    public let onPlayWordAudio: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedWord: WordAnalysis?

    public init(
        result: SpeechAnalysisResult,
        onRetry: @escaping () -> Void,
        onNext: @escaping () -> Void,
        onPlayWordAudio: @escaping (String) -> Void
    ) {
        self.result = result
        self.onRetry = onRetry
        self.onNext = onNext
        self.onPlayWordAudio = onPlayWordAudio
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Overall Score Circular Gauge
                    ScoreGaugeView(score: result.overallScore, size: 140, lineWidth: 14)
                        .padding(.top, 10)

                    // Tri-Metric Sub-Scores
                    HStack(spacing: 12) {
                        metricCard(title: "Accuracy", value: "\(result.pronunciationAccuracy)%", icon: "target", color: .green)
                        metricCard(title: "Fluency", value: "\(result.fluencyScore)%", icon: "waveform", color: .blue)
                        metricCard(title: "Completeness", value: "\(result.completenessScore)%", icon: "checkmark.circle", color: .purple)
                    }

                    // Coach Feedback Tip Box
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "sparkles")
                                .foregroundColor(.yellow)
                            Text("Coach Feedback")
                                .font(.headline)
                                .fontWeight(.bold)
                        }

                        Text(result.coachTip)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineSpacing(3)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(UIColor.secondarySystemBackground))
                    )

                    // Word-by-Word Breakdown
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Word-by-Word Accuracy")
                            .font(.headline)
                            .fontWeight(.bold)

                        Text("Tap any word to hear its pronunciation and coaching notes.")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        // Flowing word chips
                        FlowLayout(spacing: 8) {
                            ForEach(result.words) { word in
                                WordScorePill(
                                    wordAnalysis: word,
                                    onPlayAudio: {
                                        onPlayWordAudio(word.targetWord)
                                    },
                                    onTapDetails: {
                                        selectedWord = word
                                    }
                                )
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(UIColor.secondarySystemBackground))
                    )

                    // Spoken Transcription Comparison
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Transcription Comparison")
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        VStack(alignment: .leading, spacing: 6) {
                            HStack(alignment: .top, spacing: 6) {
                                Text("Target:")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.secondary)
                                    .frame(width: 50, alignment: .leading)
                                Text(result.targetSentence)
                                    .font(.caption)
                                    .foregroundColor(.primary)
                            }

                            HStack(alignment: .top, spacing: 6) {
                                Text("Heard:")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.secondary)
                                    .frame(width: 50, alignment: .leading)
                                Text(result.transcribedSentence.isEmpty ? "(Nothing recognized)" : result.transcribedSentence)
                                    .font(.caption)
                                    .foregroundColor(result.transcribedSentence.isEmpty ? .red : .blue)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color(UIColor.tertiarySystemBackground))
                    )

                    // Action Buttons
                    HStack(spacing: 12) {
                        Button(action: {
                            dismiss()
                            onRetry()
                        }) {
                            Label("Practice Again", systemImage: "arrow.counterclockwise")
                                .font(.headline)
                                .foregroundColor(.primary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(Color(UIColor.secondarySystemBackground))
                                )
                        }

                        Button(action: {
                            dismiss()
                            onNext()
                        }) {
                            Label("Next Phrase", systemImage: "arrow.right")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(Color.blue)
                                )
                        }
                    }
                    .padding(.bottom, 20)
                }
                .padding(.horizontal, 20)
            }
            .navigationTitle("Session Results")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .sheet(item: $selectedWord) { word in
                WordDetailModal(word: word, onPlayAudio: {
                    onPlayWordAudio(word.targetWord)
                })
                .presentationDetents([.height(260)])
            }
        }
    }

    private func metricCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)

            Text(value)
                .font(.title3)
                .fontWeight(.bold)

            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(UIColor.secondarySystemBackground))
        )
    }
}

// MARK: - Word Detail Modal
private struct WordDetailModal: View {
    let word: WordAnalysis
    let onPlayAudio: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(word.targetWord)
                        .font(.title2)
                        .fontWeight(.bold)

                    if let hint = word.phoneticHint {
                        Text(hint)
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                }

                Spacer()

                Button(action: onPlayAudio) {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(Color.blue))
                }
            }

            Divider()

            HStack {
                Label(word.status.rawValue, systemImage: word.status.systemIcon)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Spacer()

                Text("Accuracy: \(Int(word.score))%")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
            }

            Text(word.feedback)
                .font(.body)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()
        }
        .padding(24)
    }
}

// MARK: - FlowLayout Helper for Word Chips
public struct FlowLayout: Layout {
    public var spacing: CGFloat

    public init(spacing: CGFloat = 8) {
        self.spacing = spacing
    }

    public func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        var height: CGFloat = 0
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > width && currentX > 0 {
                currentX = 0
                currentY += rowHeight + spacing
                rowHeight = 0
            }
            rowHeight = max(rowHeight, size.height)
            currentX += size.width + spacing
        }
        height = currentY + rowHeight
        return CGSize(width: width, height: height)
    }

    public func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var currentX: CGFloat = bounds.minX
        var currentY: CGFloat = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > bounds.maxX && currentX > bounds.minX {
                currentX = bounds.minX
                currentY += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: currentX, y: currentY), proposal: ProposedViewSize(size))
            rowHeight = max(rowHeight, size.height)
            currentX += size.width + spacing
        }
    }
}
