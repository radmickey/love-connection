import SwiftUI

struct InviteLinkView: View {
    @Environment(\.dismiss) var dismiss
    @State private var inviteLink: String?
    @State private var username: String?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showCopiedAlert = false

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

                VStack(spacing: 32) {
                    if isLoading {
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.2)
                            Text("Generating link...")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if let inviteLink = inviteLink, let username = username {
                        ScrollView {
                            VStack(spacing: 32) {
                                Spacer()
                                    .frame(height: 20)

                                // Header
                                VStack(spacing: 16) {
                                    ZStack {
                                        Circle()
                                            .fill(
                                                LinearGradient(
                                                    colors: [.pink.opacity(0.2), .red.opacity(0.1)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .frame(width: 120, height: 120)

                                        Image(systemName: "link.circle.fill")
                                            .font(.system(size: 60))
                                            .foregroundStyle(
                                                LinearGradient(
                                                    colors: [.pink, .red],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                    }

                                    VStack(spacing: 8) {
                                        Text("Your Invite Link")
                                            .font(.system(size: 28, weight: .bold, design: .rounded))

                                        Text("Share this link with your partner to connect")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                            .multilineTextAlignment(.center)
                                            .padding(.horizontal, 32)
                                    }
                                }

                                // Link card
                                VStack(spacing: 20) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Invite Link")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.secondary)
                                            .textCase(.uppercase)
                                            .tracking(0.5)

                                        Text(inviteLink)
                                            .font(.system(.body, design: .monospaced))
                                            .foregroundColor(.primary)
                                            .padding(16)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .background(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(.ultraThinMaterial)
                                            )
                                    }

                                    // Action buttons
                                    VStack(spacing: 12) {
                                        Button(action: {
                                            UIPasteboard.general.string = inviteLink
                                            showCopiedAlert = true
                                        }) {
                                            HStack {
                                                Image(systemName: "doc.on.doc.fill")
                                                Text("Copy Link")
                                                    .font(.system(size: 18, weight: .semibold))
                                            }
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 56)
                                            .background(
                                                LinearGradient(
                                                    colors: [.blue, .purple],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                            .foregroundColor(.white)
                                            .cornerRadius(16)
                                            .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
                                        }

                                        ShareLink(item: inviteLink) {
                                            HStack {
                                                Image(systemName: "square.and.arrow.up.fill")
                                                Text("Share")
                                                    .font(.system(size: 18, weight: .semibold))
                                            }
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 56)
                                            .background(
                                                RoundedRectangle(cornerRadius: 16)
                                                    .fill(.ultraThinMaterial)
                                            )
                                            .foregroundColor(.primary)
                                        }
                                    }
                                }
                                .padding(24)
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(.ultraThinMaterial)
                                        .shadow(color: .black.opacity(0.1), radius: 15, x: 0, y: 5)
                                )
                                .padding(.horizontal, 24)

                                Spacer()
                                    .frame(height: 20)
                            }
                        }
                    } else if let errorMessage = errorMessage {
                        VStack(spacing: 24) {
                            ZStack {
                                Circle()
                                    .fill(.red.opacity(0.1))
                                    .frame(width: 120, height: 120)

                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(.red)
                            }

                            VStack(spacing: 8) {
                                Text("Error")
                                    .font(.system(size: 24, weight: .bold, design: .rounded))

                                Text(errorMessage)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 32)
                            }

                            Button(action: loadInviteLink) {
                                HStack {
                                    Image(systemName: "arrow.clockwise")
                                    Text("Retry")
                                        .font(.system(size: 18, weight: .semibold))
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(
                                    LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .foregroundColor(.white)
                                .cornerRadius(16)
                                .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
                            }
                            .padding(.horizontal, 24)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
            }
            .navigationTitle("Invite Link")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Copied!", isPresented: $showCopiedAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Link copied to clipboard")
            }
            .onAppear {
                loadInviteLink()
            }
        }
    }

    private func loadInviteLink() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                let result = try await APIService.shared.generateInviteLink()
                inviteLink = result.link
                username = result.username
            } catch {
                errorMessage = ErrorFormatter.userFriendlyMessage(from: error)
            }
            isLoading = false
        }
    }
}

