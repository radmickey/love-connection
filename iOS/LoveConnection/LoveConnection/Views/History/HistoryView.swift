import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var appState: AppState
    @State private var events: [LoveEvent] = []
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
                    } else if events.isEmpty {
                        VStack(spacing: 20) {
                            ZStack {
                                Circle()
                                    .fill(.secondary.opacity(0.1))
                                    .frame(width: 120, height: 120)

                                Image(systemName: "heart.slash")
                                    .font(.system(size: 60))
                                    .foregroundColor(.secondary)
                            }

                            VStack(spacing: 8) {
                                Text("No events yet")
                                    .font(.system(size: 22, weight: .bold, design: .rounded))

                                Text("Start sending love to see history here")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 32)
                            }
                        }
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(events) { event in
                                    HistoryRow(event: event, currentUserId: appState.currentUser?.id)
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 16)
                        }
                    }
                }
            }
            .navigationTitle("History")
            .refreshable {
                await loadHistory()
            }
            .task {
                await loadHistory()
            }
        }
    }

    private func loadHistory() async {
        isLoading = true
        errorMessage = nil

        do {
            events = try await APIService.shared.getLoveHistory()
        } catch {
            errorMessage = ErrorFormatter.userFriendlyMessage(from: error)
        }

        isLoading = false
    }
}

struct HistoryRow: View {
    let event: LoveEvent
    let currentUserId: UUID?

    var isFromMe: Bool {
        event.sender?.id == currentUserId
    }

    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: isFromMe ? [.pink.opacity(0.2), .red.opacity(0.1)] : [.blue.opacity(0.2), .purple.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)

                Image(systemName: "heart.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(
                        LinearGradient(
                            colors: isFromMe ? [.pink, .red] : [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            // Content
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(isFromMe ? "You" : (event.sender?.username ?? "Unknown"))
                        .font(.system(size: 18, weight: .semibold, design: .rounded))

                    Spacer()

                    Text(event.formattedDuration)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.pink, .red],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }

                Text(event.createdAt, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
}

