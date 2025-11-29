import SwiftUI
import Foundation

struct ProfileView: View {
    // Username validation: starts with letter, only alphanumeric, max 12 chars
    private let usernamePattern = "^[a-zA-Z][a-zA-Z0-9]*$"
    @EnvironmentObject var appState: AppState
    @State private var username: String = ""
    @State private var isEditing: Bool = false
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var showingLogoutAlert = false
    @State private var showingBreakPairAlert = false

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
                    VStack(spacing: 24) {
                        // Profile header
                        if let user = appState.currentUser {
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

                                    Image(systemName: "person.circle.fill")
                                        .font(.system(size: 70))
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [.pink, .red],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                }

                                Text(user.username)
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                            }
                            .padding(.top, 20)
                            .padding(.bottom, 8)
                        }

                        // Profile information card
                        VStack(spacing: 0) {
                            if let user = appState.currentUser {
                                // Username section
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Username")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.secondary)
                                        .textCase(.uppercase)
                                        .tracking(0.5)

                                    if isEditing {
                                        TextField("Username", text: $username)
                                            .textFieldStyle(.plain)
                                            .font(.system(size: 18))
                                            .textInputAutocapitalization(.never)
                                            .autocorrectionDisabled()
                                            .padding(16)
                                            .background(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(.ultraThinMaterial)
                                            )
                                            .onChange(of: username) { newValue in
                                                // Remove spaces as user types
                                                if newValue.contains(" ") {
                                                    username = newValue.replacingOccurrences(of: " ", with: "")
                                                }
                                                // Limit to 12 characters
                                                if newValue.count > 12 {
                                                    username = String(newValue.prefix(12))
                                                }
                                            }

                                        // Rules hint
                                        HStack {
                                            Image(systemName: "info.circle.fill")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                            Text("3-12 characters, letters and numbers only")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            Spacer()
                                            Text("\(username.count)/12")
                                                .font(.caption2)
                                                .foregroundColor(username.count > 12 ? .red : .secondary)
                                        }
                                        .padding(.horizontal, 4)
                                    } else {
                                        Text(user.username)
                                            .font(.system(size: 18, weight: .medium))
                                            .foregroundColor(.primary)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .padding(.vertical, 8)
                                    }
                                }
                                .padding(20)
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(.ultraThinMaterial)
                                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                                )

                                // Email section (if available)
                                if let email = user.email {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Email")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.secondary)
                                            .textCase(.uppercase)
                                            .tracking(0.5)

                                        Text(email)
                                            .font(.system(size: 16))
                                            .foregroundColor(.primary)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                    .padding(20)
                                    .background(
                                        RoundedRectangle(cornerRadius: 20)
                                            .fill(.ultraThinMaterial)
                                            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                                    )
                                    .padding(.top, 12)
                                }
                            }
                        }
                        .padding(.horizontal, 24)

                        // Action buttons
                        VStack(spacing: 12) {
                            if isEditing {
                                Button(action: saveUsername) {
                                    HStack {
                                        if isLoading {
                                            ProgressView()
                                                .progressViewStyle(.circular)
                                                .tint(.white)
                                        } else {
                                            Image(systemName: "checkmark.circle.fill")
                                            Text("Save")
                                                .font(.system(size: 18, weight: .semibold))
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(
                                        LinearGradient(
                                            colors: username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || username.trimmingCharacters(in: .whitespacesAndNewlines) == appState.currentUser?.username || isLoading ? [.gray.opacity(0.3)] : [.blue, .purple],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .foregroundColor(.white)
                                    .cornerRadius(16)
                                    .shadow(color: username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .clear : .blue.opacity(0.3), radius: 10, x: 0, y: 5)
                                }
                                .disabled(username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || username.trimmingCharacters(in: .whitespacesAndNewlines) == appState.currentUser?.username || isLoading)

                                Button(action: cancelEditing) {
                                    Text("Cancel")
                                        .font(.system(size: 18, weight: .semibold))
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 56)
                                        .background(
                                            LinearGradient(
                                                colors: [.gray.opacity(0.3), .gray.opacity(0.2)],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .foregroundColor(.primary)
                                        .cornerRadius(16)
                                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                                }
                            } else {
                                Button(action: startEditing) {
                                    HStack {
                                        Image(systemName: "pencil.circle.fill")
                                        Text("Edit Username")
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
                            }

                            // Break pair button (if user has a pair)
                            if appState.currentPair != nil {
                                Button(role: .destructive, action: {
                                    showingBreakPairAlert = true
                                }) {
                                    HStack {
                                        Image(systemName: "heart.slash.fill")
                                        Text("Break Connection")
                                            .font(.system(size: 18, weight: .semibold))
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(.red.opacity(0.1))
                                    )
                                    .foregroundColor(.red)
                                }
                            }

                            Button(role: .destructive, action: {
                                showingLogoutAlert = true
                            }) {
                                HStack {
                                    Image(systemName: "arrow.right.square.fill")
                                    Text("Logout")
                                        .font(.system(size: 18, weight: .semibold))
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(.red.opacity(0.1))
                                )
                                .foregroundColor(.red)
                            }
                        }
                        .padding(.horizontal, 24)

                        // Error message
                        if let errorMessage = errorMessage {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.circle.fill")
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
                            .frame(height: 20)
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if let user = appState.currentUser {
                    username = user.username
                }
            }
            .alert("Logout", isPresented: $showingLogoutAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Logout", role: .destructive) {
                    appState.logout()
                }
            } message: {
                Text("Are you sure you want to logout?")
            }
            .alert("Break Connection", isPresented: $showingBreakPairAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Break", role: .destructive) {
                    Task {
                        await appState.deletePair()
                    }
                }
            } message: {
                Text("Are you sure you want to break the connection with your partner? This action cannot be undone.")
            }
            .disabled(isLoading)
        }
    }

    private func startEditing() {
        if let user = appState.currentUser {
            username = user.username
        }
        isEditing = true
        errorMessage = nil
    }

    private func cancelEditing() {
        if let user = appState.currentUser {
            username = user.username
        }
        isEditing = false
        errorMessage = nil
    }

    private func isValidUsername(_ username: String) -> Bool {
        // Check if username matches pattern: starts with letter, only alphanumeric
        let regex = try? NSRegularExpression(pattern: usernamePattern, options: [])
        let range = NSRange(location: 0, length: username.utf16.count)
        return regex?.firstMatch(in: username, options: [], range: range) != nil
    }

    private func saveUsername() {
        let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedUsername.isEmpty else {
            errorMessage = "Username cannot be empty"
            return
        }

        // Check for spaces
        guard !trimmedUsername.contains(" ") else {
            errorMessage = "Username cannot contain spaces"
            return
        }

        guard trimmedUsername.count >= 3 else {
            errorMessage = "Username must be at least 3 characters"
            return
        }

        guard trimmedUsername.count <= 12 else {
            errorMessage = "Username must be 12 characters or less"
            return
        }

        // Validate format: starts with letter, only alphanumeric
        guard isValidUsername(trimmedUsername) else {
            errorMessage = "Username must start with a letter and contain only letters and numbers"
            return
        }

        guard trimmedUsername != appState.currentUser?.username else {
            cancelEditing()
            return
        }

        isLoading = true
        errorMessage = nil

        Task {
            do {
                let updatedUser = try await APIService.shared.updateUsername(trimmedUsername)
                await MainActor.run {
                    appState.currentUser = updatedUser
                    isEditing = false
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = ErrorFormatter.userFriendlyMessage(from: error)
                    isLoading = false
                }
            }
        }
    }
}

