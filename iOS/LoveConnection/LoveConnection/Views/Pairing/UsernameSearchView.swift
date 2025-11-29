import SwiftUI

struct UsernameSearchView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState
    @State private var username = ""
    @State private var errorMessage: String?
    @State private var isSearching = false
    @State private var foundUser: User?

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

                VStack(spacing: 24) {
                    // Search field
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Search for your partner")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .padding(.top, 8)

                        HStack(spacing: 12) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.secondary)

                            TextField("Enter username", text: $username)
                                .textFieldStyle(.plain)
                                .font(.system(size: 16))
                                .autocapitalization(.none)
                                .autocorrectionDisabled()
                                .submitLabel(.search)
                                .onSubmit {
                                    searchUser()
                                }
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.ultraThinMaterial)
                                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                        )

                        Button(action: searchUser) {
                            HStack {
                                if isSearching {
                                    ProgressView()
                                        .progressViewStyle(.circular)
                                        .tint(.white)
                                } else {
                                    Text("Search")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                LinearGradient(
                                    colors: username.isEmpty || isSearching ? [.gray.opacity(0.3)] : [.blue, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .shadow(color: username.isEmpty ? .clear : .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .disabled(username.isEmpty || isSearching)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)

                    // Results
                    if isSearching {
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.2)
                            Text("Searching...")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else if let foundUser = foundUser {
                        VStack(spacing: 24) {
                            // User card
                            VStack(spacing: 16) {
                                ZStack {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [.blue.opacity(0.2), .purple.opacity(0.1)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 100, height: 100)

                                    Image(systemName: "person.circle.fill")
                                        .font(.system(size: 60))
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [.blue, .purple],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                }

                                Text(foundUser.username)
                                    .font(.system(size: 24, weight: .bold, design: .rounded))

                                Button(action: sendPairRequest) {
                                    HStack {
                                        Image(systemName: "heart.fill")
                                        Text("Send Pair Request")
                                            .font(.system(size: 16, weight: .semibold))
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(
                                        LinearGradient(
                                            colors: [.pink, .red],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                                    .shadow(color: .pink.opacity(0.3), radius: 10, x: 0, y: 5)
                                }
                            }
                            .padding(24)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(.ultraThinMaterial)
                                    .shadow(color: .black.opacity(0.1), radius: 15, x: 0, y: 5)
                            )
                            .padding(.horizontal, 24)
                        }
                        .transition(.scale.combined(with: .opacity))
                    }

                    if let errorMessage = errorMessage {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                            Text(errorMessage)
                                .font(.subheadline)
                        }
                        .foregroundColor(.red)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(.red.opacity(0.1))
                        )
                        .padding(.horizontal, 24)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }

                    Spacer()
                }
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func searchUser() {
        guard !username.isEmpty else {
            errorMessage = "Please enter a username"
            return
        }

        isSearching = true
        errorMessage = nil
        foundUser = nil

        Task {
            do {
                let user = try await APIService.shared.searchUser(username: username)
                foundUser = user
            } catch {
                errorMessage = ErrorFormatter.userFriendlyMessage(from: error)
            }
            isSearching = false
        }
    }

    private func sendPairRequest() {
        guard let foundUser = foundUser else { return }

        Task {
            do {
                _ = try await APIService.shared.createPairRequest(username: foundUser.username)
                dismiss()
            } catch {
                errorMessage = ErrorFormatter.userFriendlyMessage(from: error)
            }
        }
    }
}

