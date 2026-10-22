import SwiftUI

public struct CategoryCard: View {
    public let category: ExerciseCategory
    public let exerciseCount: Int
    public let isSelected: Bool
    public let onSelect: () -> Void

    public init(
        category: ExerciseCategory,
        exerciseCount: Int,
        isSelected: Bool,
        onSelect: @escaping () -> Void
    ) {
        self.category = category
        self.exerciseCount = exerciseCount
        self.isSelected = isSelected
        self.onSelect = onSelect
    }

    public var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(isSelected ? Color.white.opacity(0.25) : Color.blue.opacity(0.12))
                            .frame(width: 44, height: 44)

                        Image(systemName: category.iconName)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(isSelected ? .white : .blue)
                    }

                    Spacer()

                    Text("\(exerciseCount) phrases")
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(isSelected ? Color.white.opacity(0.2) : Color.gray.opacity(0.12))
                        .foregroundColor(isSelected ? .white : .secondary)
                        .cornerRadius(8)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(category.rawValue)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(isSelected ? .white : .primary)

                    Text(category.description)
                        .font(.caption)
                        .foregroundColor(isSelected ? .white.opacity(0.85) : .secondary)
                        .lineLimit(2)
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(
                        isSelected
                            ? LinearGradient(colors: [Color.blue, Color.indigo], startPoint: .topLeading, endPoint: .bottomTrailing)
                            : LinearGradient(colors: [Color(UIColor.secondarySystemBackground)], startPoint: .top, endPoint: .bottom)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(isSelected ? Color.white.opacity(0.4) : Color.gray.opacity(0.15), lineWidth: 1)
            )
            .shadow(color: isSelected ? Color.blue.opacity(0.3) : Color.black.opacity(0.03), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
}
