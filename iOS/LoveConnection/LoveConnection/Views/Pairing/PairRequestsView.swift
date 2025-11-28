import SwiftUI

struct PairRequestsView: View {
    @EnvironmentObject var appState: AppState
    @State private var requests: [PairRequest] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView()
                } else if requests.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "heart.slash")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        Text("No pending requests")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                } else {
                    List(requests) { request in
                        PairRequestRow(request: request) {
                            await respondToRequest(request, accept: true)
                        } onReject: {
                            await respondToRequest(request, accept: false)
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
            errorMessage = error.localizedDescription
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
            errorMessage = error.localizedDescription
        }
    }
}

struct PairRequestRow: View {
    let request: PairRequest
    let onAccept: () async -> Void
    let onReject: () async -> Void
    @State private var isProcessing = false

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(request.requester?.username ?? "Unknown")
                    .font(.headline)

                Text("wants to connect with you")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            HStack(spacing: 12) {
                Button(action: {
                    Task {
                        isProcessing = true
                        await onReject()
                        isProcessing = false
                    }
                }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.red)
                }
                .disabled(isProcessing)

                Button(action: {
                    Task {
                        isProcessing = true
                        await onAccept()
                        isProcessing = false
                    }
                }) {
                    Image(systemName: "checkmark")
                        .foregroundColor(.green)
                }
                .disabled(isProcessing)
            }
        }
        .padding(.vertical, 4)
    }
}

