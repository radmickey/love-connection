import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        TabView {
            if appState.currentPair != nil {
                HeartButtonView()
                    .tabItem {
                        Label("Heart", systemImage: "heart.fill")
                    }

                HistoryView()
                    .tabItem {
                        Label("History", systemImage: "clock.fill")
                    }

                StatsView()
                    .tabItem {
                        Label("Stats", systemImage: "chart.bar.fill")
                    }
            } else {
                PairingView()
                    .tabItem {
                        Label("Pairing", systemImage: "heart.fill")
                    }
            }

            ProfileView()
                .environmentObject(appState)
                .tabItem {
                    Label("Profile", systemImage: "person.circle.fill")
                }
        }
    }
}

