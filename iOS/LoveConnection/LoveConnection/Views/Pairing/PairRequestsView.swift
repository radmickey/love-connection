import SwiftUI

struct PairRequestsView: View {
    @EnvironmentObject var appState: AppState
    @State private var requests: [PairRequest] = []
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
                    } else if requests.isEmpty {
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
                                Text("No pending requests")
                                    .font(.system(size: 22, weight: .bold, design: .rounded))

                                Text("When someone sends you a request, it will appear here")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 32)
                            }
                        }
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(requests) { request in
                                    PairRequestRow(request: request) {
                                        await respondToRequest(request, accept: true)
                                    } onReject: {
                                        await respondToRequest(request, accept: false)
                                    }
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 16)
                        }
                    }
                }
            }
            .navigationTitle("Pair Requests")
            .refreshable {
                await loadRequests()
            }
            .task {
                await loadRequests()
            }
        }
    }

    private func loadRequests() async {
        isLoading = true
        errorMessage = nil

        do {
            requests = try await APIService.shared.getPairRequests()
        } catch {
            errorMessage = ErrorFormatter.userFriendlyMessage(from: error)
        }

        isLoading = false
    }

    private func respondToRequest(_ request: PairRequest, accept: Bool) async {
        do {
            if let pair = try await APIService.shared.respondPairRequest(requestId: request.id, accept: accept) {
                appState.currentPair = pair
                await appState.loadCurrentPair()
            }
            await loadRequests()
        } catch {
            errorMessage = ErrorFormatter.userFriendlyMessage(from: error)
        }
    }
}

struct PairRequestRow: View {
    let request: PairRequest
    let onAccept: () async -> Void
    let onReject: () async -> Void
    @State private var isProcessing = false

    var body: some View {
        HStack(spacing: 16) {
            // Avatar
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue.opacity(0.2), .purple.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)

                Image(systemName: "person.circle.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            // Content
            VStack(alignment: .leading, spacing: 6) {
                Text(request.requester?.username ?? "Unknown")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.black)

                Text("wants to connect with you")
                    .font(.caption)
                    .foregroundColor(.black.opacity(0.6))
            }

            Spacer()

            // Action buttons
            HStack(spacing: 12) {
                Button(action: {
                    Task {
                        isProcessing = true
                        await onReject()
                        isProcessing = false
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.red)
                        .opacity(isProcessing ? 0.5 : 1.0)
                }
                .disabled(isProcessing)

                Button(action: {
                    Task {
                        isProcessing = true
                        await onAccept()
                        isProcessing = false
                    }
                }) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.green)
                        .opacity(isProcessing ? 0.5 : 1.0)
                }
                .disabled(isProcessing)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.9))
                .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 5)
        )
    }
}

