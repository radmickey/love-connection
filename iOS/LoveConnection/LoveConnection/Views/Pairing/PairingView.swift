import SwiftUI

struct PairingView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingUsernameSearch = false
    @State private var showingInviteLink = false

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

                ScrollView {
                    VStack(spacing: 40) {
                        Spacer()
                            .frame(height: 20)

                        // Header section
                        VStack(spacing: 20) {
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

                                Image(systemName: "heart.fill")
                                    .font(.system(size: 60))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.pink, .red],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            }

                            VStack(spacing: 12) {
                                Text("No partner connected yet")
                                    .font(.system(size: 24, weight: .bold, design: .rounded))
                                    .foregroundColor(.black)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(Color.white.opacity(0.9))
                                            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                                    )

                                Text("Connect with your partner")
                                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                                    .foregroundColor(.black.opacity(0.8))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(Color.white.opacity(0.9))
                                            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                                    )

                                Text("Search by username or share your invite link")
                                    .font(.subheadline)
                                    .foregroundColor(.black.opacity(0.6))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 32)
                                    .padding(.top, 4)
                            }
                        }
                        .padding(.horizontal, 24)

                        // Action buttons
                        VStack(spacing: 16) {
                            // Search by username button
                            Button(action: { showingUsernameSearch = true }) {
                                HStack(spacing: 16) {
                                    ZStack {
                                        Circle()
                                            .fill(
                                                LinearGradient(
                                                    colors: [.blue, .purple],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .frame(width: 56, height: 56)

                                        Image(systemName: "person.circle.fill")
                                            .font(.system(size: 28))
                                            .foregroundColor(.white)
                                    }

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Search by Username")
                                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundColor(.primary)

                                        Text("Find your partner")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.secondary)
                                }
                                .padding(20)
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(.ultraThinMaterial)
                                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                                )
                            }
                            .buttonStyle(.plain)

                            // Share invite link button
                            Button(action: { showingInviteLink = true }) {
                                HStack(spacing: 16) {
                                    ZStack {
                                        Circle()
                                            .fill(
                                                LinearGradient(
                                                    colors: [.pink, .red],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .frame(width: 56, height: 56)

                                        Image(systemName: "link.circle.fill")
                                            .font(.system(size: 28))
                                            .foregroundColor(.white)
                                    }

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Share Invite Link")
                                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundColor(.primary)

                                        Text("Send link to your partner")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.secondary)
                                }
                                .padding(20)
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(.ultraThinMaterial)
                                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                                )
                            }
                            .buttonStyle(.plain)

                            // Pair requests button
                            NavigationLink(destination: PairRequestsView()) {
                                HStack(spacing: 16) {
                                    ZStack {
                                        Circle()
                                            .fill(
                                                LinearGradient(
                                                    colors: [.orange, .yellow],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .frame(width: 56, height: 56)

                                        Image(systemName: "person.2.fill")
                                            .font(.system(size: 28))
                                            .foregroundColor(.white)
                                    }

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Pair Requests")
                                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundColor(.primary)

                                        Text("View pending requests")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.secondary)
                                }
                                .padding(20)
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(.ultraThinMaterial)
                                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 24)

                        Spacer()
                            .frame(height: 40)
                    }
                }
            }
            .navigationTitle("Connect")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingUsernameSearch) {
                UsernameSearchView()
            }
            .sheet(isPresented: $showingInviteLink) {
                InviteLinkView()
            }
        }
    }
}

