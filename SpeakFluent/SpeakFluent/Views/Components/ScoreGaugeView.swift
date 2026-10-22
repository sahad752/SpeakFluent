import SwiftUI

public struct ScoreGaugeView: View {
    public let score: Int
    public let size: CGFloat
    public let lineWidth: CGFloat

    public init(score: Int, size: CGFloat = 130, lineWidth: CGFloat = 12) {
        self.score = score
        self.size = size
        self.lineWidth = lineWidth
    }

    private var progress: Double {
        Double(min(max(score, 0), 100)) / 100.0
    }

    private var scoreGradient: AngularGradient {
        if score >= 85 {
            return AngularGradient(
                colors: [.green, .mint, .teal, .green],
                center: .center,
                startAngle: .degrees(0),
                endAngle: .degrees(360)
            )
        } else if score >= 70 {
            return AngularGradient(
                colors: [.blue, .cyan, .teal, .blue],
                center: .center,
                startAngle: .degrees(0),
                endAngle: .degrees(360)
            )
        } else if score >= 50 {
            return AngularGradient(
                colors: [.orange, .yellow, .orange],
                center: .center,
                startAngle: .degrees(0),
                endAngle: .degrees(360)
            )
        } else {
            return AngularGradient(
                colors: [.red, .pink, .red],
                center: .center,
                startAngle: .degrees(0),
                endAngle: .degrees(360)
            )
        }
    }

    private var feedbackLabel: String {
        switch score {
        case 90...100: return "Native Fluency"
        case 80...89: return "Fluent & Clear"
        case 65...79: return "Good Effort"
        default: return "Keep Practicing"
        }
    }

    public var body: some View {
        VStack(spacing: 6) {
            ZStack {
                // Background Track
                Circle()
                    .stroke(
                        Color.gray.opacity(0.18),
                        lineWidth: lineWidth
                    )

                // Foreground Progress Arc
                Circle()
                    .trim(from: 0.0, to: CGFloat(progress))
                    .stroke(
                        scoreGradient,
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.8, dampingFraction: 0.75), value: progress)

                // Score text
                VStack(spacing: 2) {
                    Text("\(score)")
                        .font(.system(size: size * 0.32, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)

                    Text("POINTS")
                        .font(.system(size: size * 0.08, weight: .semibold))
                        .foregroundColor(.secondary)
                        .tracking(1.2)
                }
            }
            .frame(width: size, height: size)

            Text(feedbackLabel)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
        }
    }
}
