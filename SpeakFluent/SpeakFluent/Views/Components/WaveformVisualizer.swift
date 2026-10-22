import SwiftUI

public struct WaveformVisualizer: View {
    public let levels: [CGFloat]
    public let isRecording: Bool

    public init(levels: [CGFloat], isRecording: Bool) {
        self.levels = levels
        self.isRecording = isRecording
    }

    public var body: some View {
        Canvas { context, size in
            let barCount = levels.count
            guard barCount > 0 else { return }

            let totalSpacing: CGFloat = CGFloat(barCount - 1) * 3.0
            let availableWidth = size.width - 32.0 // padding
            let barWidth: CGFloat = max(3.0, (availableWidth - totalSpacing) / CGFloat(barCount))
            let startX: CGFloat = (size.width - (CGFloat(barCount) * barWidth + totalSpacing)) / 2.0
            let centerY = size.height / 2.0

            let activeGradient = Gradient(colors: [.cyan, .blue, .indigo])
            let idleGradient = Gradient(colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.5)])
            let gradientShader = GraphicsContext.Shading.linearGradient(
                isRecording ? activeGradient : idleGradient,
                startPoint: CGPoint(x: 0, y: size.height),
                endPoint: CGPoint(x: 0, y: 0)
            )

            for i in 0..<barCount {
                let level = levels[i]
                let barHeight = isRecording ? max(6.0, level * (size.height - 12.0)) : 6.0
                let x = startX + CGFloat(i) * (barWidth + 3.0)
                let y = centerY - (barHeight / 2.0)

                let rect = CGRect(x: x, y: y, width: barWidth, height: barHeight)
                let path = Path(roundedRect: rect, cornerRadius: barWidth / 2.0)
                context.fill(path, with: gradientShader)
            }
        }
        .frame(height: 56)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemBackground).opacity(0.8))
        )
    }
}
