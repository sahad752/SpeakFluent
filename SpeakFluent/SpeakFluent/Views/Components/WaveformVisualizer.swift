import SwiftUI

public struct WaveformVisualizer: View {
    public let levels: [CGFloat]
    public let isRecording: Bool

    public init(levels: [CGFloat], isRecording: Bool) {
        self.levels = levels
        self.isRecording = isRecording
    }

    public var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<levels.count, id: \.self) { index in
                let level = levels[index]
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: isRecording
                                ? [Color.cyan, Color.blue, Color.indigo]
                                : [Color.gray.opacity(0.3), Color.gray.opacity(0.5)],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .frame(
                        width: 4,
                        height: isRecording ? max(8, level * 54) : 8
                    )
                    .animation(
                        .easeInOut(duration: 0.12),
                        value: level
                    )
            }
        }
        .frame(height: 60)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemBackground).opacity(0.8))
        )
    }
}
