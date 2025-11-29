import SwiftUI
import Foundation

struct UsernameInputView: View {
    // Username validation: starts with letter, only alphanumeric, max 12 chars
    private let usernamePattern = "^[a-zA-Z][a-zA-Z0-9]*$"
    @EnvironmentObject var appState: AppState
    @State private var username = ""
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var isLoading = false

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
                    Spacer()

                    // Header section
                    VStack(spacing: 20) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [.blue.opacity(0.2), .purple.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 120, height: 120)

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

                        VStack(spacing: 8) {
                            Text("Choose Your Username")
                                .font(.system(size: 28, weight: .bold, design: .rounded))

                            Text("Pick a unique username that your partner can use to find you")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }
                    }

                    // Input section
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Username")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)

                            TextField("Enter username", text: $username)
                                .textFieldStyle(.plain)
                                .font(.system(size: 18))
                                .autocapitalization(.none)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(.ultraThinMaterial)
                                        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
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
                                .submitLabel(.done)
                                .onSubmit {
                                    if !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                        saveUsername()
                                    }
                                }

                            // Rules hint
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 4) {
                                    Image(systemName: "info.circle.fill")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    Text("3-12 characters, letters and numbers only")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                Text("\(username.count)/12")
                                    .font(.caption2)
                                    .foregroundColor(username.count > 12 ? .red : .secondary)
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                            }
                            .padding(.horizontal, 4)
                        }

                        Button(action: saveUsername) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(.circular)
                                        .tint(.white)
                                } else {
                                    Text("Continue")
                                        .font(.system(size: 18, weight: .semibold))
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                LinearGradient(
                                    colors: username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading ? [.gray.opacity(0.3)] : [.blue, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(16)
                            .shadow(color: username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .clear : .blue.opacity(0.3), radius: 10, x: 0, y: 5)
                        }
                        .disabled(isLoading || username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .animation(.easeInOut(duration: 0.2), value: username.isEmpty)
                    }
                    .padding(.horizontal, 32)
                    .frame(maxWidth: 400)

                    Spacer()
                }
            }
            .navigationTitle("Setup")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                }
            }
        }
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
            errorMessage = "Username is required"
            showError = true
            return
        }

        // Check for spaces
        guard !trimmedUsername.contains(" ") else {
            errorMessage = "Username cannot contain spaces"
            showError = true
            return
        }

        guard trimmedUsername.count >= 3 else {
            errorMessage = "Username must be at least 3 characters"
            showError = true
            return
        }

        guard trimmedUsername.count <= 12 else {
            errorMessage = "Username must be 12 characters or less"
            showError = true
            return
        }

        // Validate format: starts with letter, only alphanumeric
        guard isValidUsername(trimmedUsername) else {
            errorMessage = "Username must start with a letter and contain only letters and numbers"
            showError = true
            return
        }

        // Use trimmed username
        username = trimmedUsername

        isLoading = true
        errorMessage = nil
        showError = false

        Task {
            do {
                let updatedUser = try await APIService.shared.updateUsername(username)
                appState.currentUser = updatedUser
                appState.needsUsernameSetup = false
                await appState.loadCurrentPair()
                NotificationService.shared.sendDeviceTokenIfAuthenticated()
            } catch {
                errorMessage = ErrorFormatter.userFriendlyMessage(from: error)
                showError = true
            }
            isLoading = false
        }
    }
}

