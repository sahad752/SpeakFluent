import SwiftUI

public struct DailyStreakView: View {
    @ObservedObject public var progressViewModel: ProgressViewModel

    public init(progressViewModel: ProgressViewModel) {
        self.progressViewModel = progressViewModel
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Streak Hero Banner
                    streakHeroCard

                    // Performance Stats Grid
                    statsGrid

                    // Badges Section
                    achievementsSection

                    // Recent Practice History
                    historySection
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Progress & Streak")
        }
    }

    private var streakHeroCard: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("CURRENT STREAK")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white.opacity(0.8))
                        .tracking(1.2)

                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text("\(progressViewModel.userProgress.currentStreak)")
                            .font(.system(size: 44, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text(progressViewModel.userProgress.currentStreak == 1 ? "Day" : "Days")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.white.opacity(0.9))
                    }
                }

                Spacer()

                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 64, height: 64)

                    Image(systemName: "flame.fill")
                        .font(.system(size: 34))
                        .foregroundColor(.yellow)
                }
            }

            Divider()
                .overlay(Color.white.opacity(0.3))

            HStack {
                Text("Longest streak: \(progressViewModel.userProgress.longestStreak) days")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.9))

                Spacer()

                Text("Practice daily to protect your streak!")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white.opacity(0.9))
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(
                    LinearGradient(
                        colors: [Color.orange, Color.red],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .shadow(color: Color.orange.opacity(0.35), radius: 10, x: 0, y: 5)
    }

    private var statsGrid: some View {
        HStack(spacing: 12) {
            statBox(
                title: "Phrases",
                value: "\(progressViewModel.userProgress.totalPracticedPhrases)",
                icon: "text.bubble.fill",
                color: .blue
            )

            statBox(
                title: "Avg Accuracy",
                value: String(format: "%.1f%%", progressViewModel.userProgress.averageScore),
                icon: "chart.bar.fill",
                color: .green
            )

            let minutes = progressViewModel.userProgress.totalSpeakingSeconds / 60
            statBox(
                title: "Practice Time",
                value: "\(minutes) min",
                icon: "clock.fill",
                color: .purple
            )
        }
    }

    private func statBox(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)

            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)

            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemBackground))
        )
    }

    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Achievements")
                .font(.headline)
                .fontWeight(.bold)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(progressViewModel.badges) { badge in
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(badge.isUnlocked ? Color.yellow.opacity(0.2) : Color.gray.opacity(0.12))
                                    .frame(width: 52, height: 52)

                                Image(systemName: badge.iconName)
                                    .font(.system(size: 24))
                                    .foregroundColor(badge.isUnlocked ? .yellow : .gray)
                            }

                            Text(badge.title)
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.center)
                                .lineLimit(1)

                            Text(badge.description)
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                        }
                        .frame(width: 120, height: 130)
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(UIColor.secondarySystemBackground))
                        )
                        .opacity(badge.isUnlocked ? 1.0 : 0.6)
                    }
                }
            }
        }
    }

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Sessions")
                .font(.headline)
                .fontWeight(.bold)

            if progressViewModel.userProgress.history.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 28))
                        .foregroundColor(.secondary)
                    Text("No practice history yet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("Complete speaking exercises to see your progress logs here.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(UIColor.secondarySystemBackground))
                )
            } else {
                ForEach(progressViewModel.userProgress.history) { session in
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(sessionScoreColor(session.overallScore).opacity(0.15))
                                .frame(width: 44, height: 44)

                            Text("\(session.overallScore)")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(sessionScoreColor(session.overallScore))
                        }

                        VStack(alignment: .leading, spacing: 3) {
                            Text(session.targetSentence)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .lineLimit(1)

                            Text(session.date.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color(UIColor.secondarySystemBackground))
                    )
                }
            }
        }
    }

    private func sessionScoreColor(_ score: Int) -> Color {
        if score >= 85 { return .green }
        if score >= 70 { return .blue }
        if score >= 50 { return .orange }
        return .red
    }
}
