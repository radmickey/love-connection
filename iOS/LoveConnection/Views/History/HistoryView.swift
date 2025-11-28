import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var appState: AppState
    @State private var events: [LoveEvent] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView()
                } else if events.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "heart.slash")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        Text("No events yet")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                } else {
                    List(events) { event in
                        HistoryRow(event: event, currentUserId: appState.currentUser?.id)
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
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}

struct HistoryRow: View {
    let event: LoveEvent
    let currentUserId: UUID?
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(event.sender?.username ?? "Unknown")
                    .font(.headline)
                
                Text(event.createdAt, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(event.formattedDuration)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.red)
        }
        .padding(.vertical, 4)
    }
}

