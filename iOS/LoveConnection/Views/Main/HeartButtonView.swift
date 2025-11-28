import SwiftUI

struct HeartButtonView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var wsService = WebSocketService.shared
    @State private var isPressed = false
    @State private var startTime: Date?
    @State private var duration: TimeInterval = 0
    @State private var timer: Timer?
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()

                VStack {
                    if let partner = appState.currentPair?.getPartner(for: appState.currentUser?.id ?? UUID()) {
                        Text("Connected with")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        Text(partner.username)
                            .font(.title)
                            .fontWeight(.bold)
                            .padding(.bottom, 40)
                    }

                    HeartAnimationView(isAnimating: isPressed)
                        .scaleEffect(isPressed ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 0.3), value: isPressed)
                        .gesture(
                            LongPressGesture(minimumDuration: 0)
                                .onChanged { _ in
                                    startHolding()
                                }
                                .onEnded { _ in
                                    stopHolding()
                                }
                        )

                    if isPressed {
                        Text(formatDuration(duration))
                            .font(.title2)
                            .fontWeight(.semibold)
                            .padding(.top, 20)
                    } else if duration > 0 {
                        Text("Last: \(formatDuration(duration))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 20)
                    }

                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding()
                    }
                }
            }
            .navigationTitle("Love Connection")
        }
        .onAppear {
            if appState.isAuthenticated && appState.currentPair != nil {
                wsService.connect()
            }
        }
        .onDisappear {
            wsService.disconnect()
        }
        .onChange(of: wsService.receivedLoveEvent) { event in
            if let event = event {
                // Handle received love event
                print("Received love event: \(event.durationSeconds) seconds")
            }
        }
    }

    private func startHolding() {
        isPressed = true
        startTime = Date()
        duration = 0
        errorMessage = nil

        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            if let startTime = startTime {
                duration = Date().timeIntervalSince(startTime)
            }
        }
    }

    private func stopHolding() {
        isPressed = false
        timer?.invalidate()
        timer = nil

        guard let startTime = startTime, duration > 0 else { return }

        let durationSeconds = Int(duration)

        Task {
            do {
                _ = try await APIService.shared.sendLove(durationSeconds: durationSeconds)
                self.duration = duration
            } catch {
                errorMessage = error.localizedDescription
            }
        }

        self.startTime = nil
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60

        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        }
        return "\(seconds)s"
    }
}

