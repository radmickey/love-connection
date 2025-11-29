import SwiftUI

struct StatsView: View {
    @EnvironmentObject var appState: AppState
    @State private var stats: Stats?
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                // Gradient background
                LinearGradient(
                    colors: [
                        Color(red: 1.0, green: 0.9, blue: 0.95),
                        Color(red: 1.0, green: 0.95, blue: 0.98),
                        Color.white
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                Group {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(1.2)
                    } else if let stats = stats {
                        ScrollView {
                            VStack(spacing: 20) {
                                StatCard(
                                    title: "Total Events",
                                    value: "\(stats.totalEvents)",
                                    icon: "heart.fill",
                                    gradient: [.pink, .red]
                                )

                                StatCard(
                                    title: "Total Time",
                                    value: stats.formattedTotalDuration,
                                    icon: "clock.fill",
                                    gradient: [.blue, .purple]
                                )

                                StatCard(
                                    title: "Average Duration",
                                    value: formatDuration(stats.averageDurationSeconds),
                                    icon: "chart.bar.fill",
                                    gradient: [.orange, .yellow]
                                )
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 20)
                        }
                    } else {
                        VStack(spacing: 20) {
                            ZStack {
                                Circle()
                                    .fill(.secondary.opacity(0.1))
                                    .frame(width: 120, height: 120)

                                Image(systemName: "chart.bar")
                                    .font(.system(size: 60))
                                    .foregroundColor(.secondary)
                            }

                            VStack(spacing: 8) {
                                Text("No statistics yet")
                                    .font(.system(size: 22, weight: .bold, design: .rounded))

                                Text("Start sending love to see statistics")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 32)
                            }
                        }
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
            errorMessage = ErrorFormatter.userFriendlyMessage(from: error)
        }

        isLoading = false
    }

    private func formatDuration(_ seconds: Double) -> String {
        // Check for NaN or invalid values
        guard !seconds.isNaN && !seconds.isInfinite && seconds >= 0 else {
            return "0s"
        }

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
    let gradient: [Color]

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: gradient.map { $0.opacity(0.2) },
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)

                Image(systemName: icon)
                    .font(.system(size: 36))
                    .foregroundStyle(
                        LinearGradient(
                            colors: gradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            Text(value)
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundColor(.primary)

            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .tracking(0.5)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 15, x: 0, y: 5)
        )
    }
}

