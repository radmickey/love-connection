import SwiftUI

struct ProfileView: View {
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
                        .disabled(username.isEmpty || username == appState.currentUser?.username || isLoading)

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

    private func saveUsername() {
        guard !username.isEmpty, username != appState.currentUser?.username else { return }

        isLoading = true
        errorMessage = nil

        Task {
            do {
                let updatedUser = try await APIService.shared.updateUsername(username)
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

