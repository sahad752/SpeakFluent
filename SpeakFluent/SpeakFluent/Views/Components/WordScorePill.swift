import SwiftUI

public struct WordScorePill: View {
    public let wordAnalysis: WordAnalysis
    public let onPlayAudio: () -> Void
    public let onTapDetails: () -> Void

    public init(
        wordAnalysis: WordAnalysis,
        onPlayAudio: @escaping () -> Void,
        onTapDetails: @escaping () -> Void
    ) {
        self.wordAnalysis = wordAnalysis
        self.onPlayAudio = onPlayAudio
        self.onTapDetails = onTapDetails
    }

    private var statusBackgroundColor: Color {
        switch wordAnalysis.status {
        case .perfect:
            return Color.green.opacity(0.16)
        case .good:
            return Color.blue.opacity(0.16)
        case .needsWork:
            return Color.orange.opacity(0.18)
        case .missed:
            return Color.red.opacity(0.16)
        }
    }

    private var statusBorderColor: Color {
        switch wordAnalysis.status {
        case .perfect:
            return Color.green.opacity(0.7)
        case .good:
            return Color.blue.opacity(0.7)
        case .needsWork:
            return Color.orange.opacity(0.8)
        case .missed:
            return Color.red.opacity(0.7)
        }
    }

    private var statusTextColor: Color {
        switch wordAnalysis.status {
        case .perfect:
            return Color.green
        case .good:
            return Color.blue
        case .needsWork:
            return Color.orange
        case .missed:
            return Color.red
        }
    }

    public var body: some View {
        Button(action: {
            onPlayAudio()
            onTapDetails()
        }) {
            HStack(spacing: 4) {
                Text(wordAnalysis.targetWord)
                    .font(.system(.body, design: .rounded))
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                Image(systemName: wordAnalysis.status.systemIcon)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(statusTextColor)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(statusBackgroundColor)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(statusBorderColor, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
