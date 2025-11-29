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
            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "person.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)

                Text("Choose Your Username")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Pick a unique username that your partner can use to find you")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)

                VStack(spacing: 16) {
                    TextField("Username", text: $username)
                        .textFieldStyle(.roundedBorder)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
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

                    Button(action: saveUsername) {
                        if isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Continue")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isLoading || username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(.horizontal)
                .frame(maxWidth: 375)

                Spacer()
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

