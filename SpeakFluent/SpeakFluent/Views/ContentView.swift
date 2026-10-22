import SwiftUI

public struct ContentView: View {
    @StateObject private var conversationViewModel = ConversationTurnViewModel()
    @StateObject private var coachViewModel = CoachViewModel()
    @StateObject private var hubViewModel = PracticeHubViewModel()
    @StateObject private var progressViewModel = ProgressViewModel()
    @State private var selectedTab: Int = 0

    public init() {}

    public var body: some View {
        TabView(selection: $selectedTab) {
            ConversationTurnView(
                viewModel: conversationViewModel
            )
            .tabItem {
                Label("AI Voice", systemImage: "sparkles")
            }
            .tag(0)

            CoachView(
                viewModel: coachViewModel,
                progressViewModel: progressViewModel
            )
            .tabItem {
                Label("Pronunciation", systemImage: "mic.fill")
            }
            .tag(1)

            ExerciseListView(
                hubViewModel: hubViewModel,
                coachViewModel: coachViewModel,
                selectedTab: $selectedTab
            )
            .tabItem {
                Label("Drills", systemImage: "books.vertical.fill")
            }
            .tag(2)

            DailyStreakView(
                progressViewModel: progressViewModel
            )
            .tabItem {
                Label("Progress", systemImage: "flame.fill")
            }
            .tag(3)

            SettingsView(
                ttsService: coachViewModel.ttsService,
                progressViewModel: progressViewModel
            )
            .tabItem {
                Label("Settings", systemImage: "gearshape.fill")
            }
            .tag(4)
        }
        .tint(.blue)
    }
}

#Preview {
    ContentView()
}
