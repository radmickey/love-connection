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

                VStack(spacing: 0) {
                    // Partner info card
                    if let partner = appState.currentPair?.getPartner(for: appState.currentUser?.id ?? UUID()) {
                        VStack(spacing: 8) {
                            Text("Connected with")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .textCase(.uppercase)
                                .tracking(1)

                            HStack(spacing: 12) {
                                Image(systemName: "person.circle.fill")
                                    .font(.system(size: 32))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.pink, .red],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )

                                Text(partner.username)
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                    .foregroundColor(.primary)
                            }
                        }
                        .padding(.vertical, 20)
                        .padding(.horizontal, 24)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(.ultraThinMaterial)
                                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                        )
                        .padding(.horizontal, 24)
                        .padding(.top, 20)
                        .padding(.bottom, 40)
                    }

                    Spacer()

                    // Heart button with enhanced design
                    VStack(spacing: 24) {
                        ZStack {
                            // Pulsing circles background
                            if isPressed {
                                ForEach(0..<3) { index in
                                    let circleSize = 200 + CGFloat(index * 30)
                                    let opacity = max(0.0, min(1.0, 1.0 - Double(index) * 0.3))

                                    Circle()
                                        .stroke(
                                            LinearGradient(
                                                colors: [.pink.opacity(0.3), .red.opacity(0.2)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 2
                                        )
                                        .frame(width: circleSize, height: circleSize)
                                        .opacity(opacity)
                                        .animation(
                                            .easeOut(duration: 1.5)
                                            .repeatForever(autoreverses: false)
                                            .delay(Double(index) * 0.2),
                                            value: isPressed
                                        )
                                }
                            }

                            HeartAnimationView(isAnimating: isPressed)
                                .scaleEffect(isPressed ? 1.15 : 1.0)
                                .shadow(color: .red.opacity(isPressed ? 0.6 : 0.3), radius: isPressed ? 30 : 15, x: 0, y: isPressed ? 15 : 8)
                        }
                        .gesture(
                            LongPressGesture(minimumDuration: 0)
                                .onChanged { _ in
                                    startHolding()
                                }
                                .onEnded { _ in
                                    stopHolding()
                                }
                        )

                        // Duration display
                        VStack(spacing: 8) {
                            if isPressed {
                                Text(formatDuration(duration))
                                    .font(.system(size: 36, weight: .bold, design: .rounded))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.pink, .red],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .transition(.scale.combined(with: .opacity))

                                Text("Hold to send love")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } else if duration > 0 {
                                VStack(spacing: 4) {
                                    Text("Last sent")
                                        .font(.caption)
                                        .foregroundColor(.secondary)

                                    Text(formatDuration(duration))
                                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                                        .foregroundColor(.pink)
                                }
                            } else {
                                Text("Hold the heart to send love")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
                    }

                    Spacer()

                    // Error message
                    if let errorMessage = errorMessage {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.circle.fill")
                            Text(errorMessage)
                        }
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(.red.opacity(0.1))
                        )
                        .padding(.bottom, 20)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
            }
            .navigationTitle("Love")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(role: .destructive, action: {
                            Task {
                                await appState.deletePair()
                            }
                        }) {
                            Label("Break Pair", systemImage: "heart.slash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(.secondary)
                    }
                }
            }
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
                let newDuration = Date().timeIntervalSince(startTime)
                // Ensure duration is valid
                if !newDuration.isNaN && !newDuration.isInfinite && newDuration >= 0 {
                    duration = newDuration
                } else {
                    duration = 0
                }
            }
        }
    }

    private func stopHolding() {
        isPressed = false
        timer?.invalidate()
        timer = nil

        // Ensure duration is valid
        guard !duration.isNaN && !duration.isInfinite && duration > 0 else {
            duration = 0
            return
        }

        let durationSeconds = Int(duration)

        Task {
            do {
                _ = try await APIService.shared.sendLove(durationSeconds: durationSeconds)
                // Ensure we keep a valid duration value
                if !duration.isNaN && !duration.isInfinite {
                    self.duration = duration
                } else {
                    self.duration = 0
                }
            } catch {
                errorMessage = ErrorFormatter.userFriendlyMessage(from: error)
            }
        }

        self.startTime = nil
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        // Check for NaN or invalid values
        guard !duration.isNaN && !duration.isInfinite && duration >= 0 else {
            return "0s"
        }

        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60

        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        }
        return "\(seconds)s"
    }
}

