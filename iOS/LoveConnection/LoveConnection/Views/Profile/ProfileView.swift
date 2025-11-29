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

    var body: some View {
        NavigationStack {
            Form {
                Section("Profile Information") {
                    if let user = appState.currentUser {
                        HStack {
                            Text("Username")
                            Spacer()
                            if isEditing {
                                TextField("Username", text: $username)
                                    .multilineTextAlignment(.trailing)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
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
                            } else {
                                Text(user.username)
                                    .foregroundColor(.secondary)
                            }
                        }

                        if let email = user.email {
                            HStack {
                                Text("Email")
                                Spacer()
                                Text(email)
                                    .foregroundColor(.secondary)
                            }
                        }

                        HStack {
                            Text("User ID")
                            Spacer()
                            Text(user.id.uuidString.prefix(8))
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                }

                Section {
                    if isEditing {
                        Button("Save") {
                            saveUsername()
                        }
                        .disabled(username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || username.trimmingCharacters(in: .whitespacesAndNewlines) == appState.currentUser?.username || isLoading)

                        Button("Cancel", role: .cancel) {
                            cancelEditing()
                        }
                    } else {
                        Button("Edit Username") {
                            startEditing()
                        }
                    }
                }

                Section {
                    Button(role: .destructive, action: {
                        showingLogoutAlert = true
                    }) {
                        Label("Logout", systemImage: "arrow.right.square")
                    }
                }

                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
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

