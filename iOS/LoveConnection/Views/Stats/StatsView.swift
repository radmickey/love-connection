import SwiftUI

struct StatsView: View {
    @EnvironmentObject var appState: AppState
    @State private var stats: Stats?
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView()
                } else if let stats = stats {
                    VStack(spacing: 32) {
                        StatCard(
                            title: "Total Events",
                            value: "\(stats.totalEvents)",
                            icon: "heart.fill"
                        )
                        
                        StatCard(
                            title: "Total Time",
                            value: stats.formattedTotalDuration,
                            icon: "clock.fill"
                        )
                        
                        StatCard(
                            title: "Average Duration",
                            value: formatDuration(stats.averageDurationSeconds),
                            icon: "chart.bar.fill"
                        )
                    }
                    .padding()
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "chart.bar")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        Text("No statistics yet")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Statistics")
            .refreshable {
                await loadStats()
            }
            .task {
                await loadStats()
            }
        }
    }
    
    private func loadStats() async {
        isLoading = true
        errorMessage = nil
        
        do {
            stats = try await APIService.shared.getStats()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    private func formatDuration(_ seconds: Double) -> String {
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60
        
        if minutes > 0 {
            return "\(minutes)m \(secs)s"
        }
        return "\(secs)s"
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(.red)
            
            Text(value)
                .font(.system(size: 32, weight: .bold))
            
            Text(title)
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

