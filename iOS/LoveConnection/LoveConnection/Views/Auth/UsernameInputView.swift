import SwiftUI

struct UsernameInputView: View {
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
                        .submitLabel(.done)
                        .onSubmit {
                            if !username.isEmpty {
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
                    .disabled(isLoading || username.isEmpty)
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

    private func saveUsername() {
        guard !username.isEmpty else {
            errorMessage = "Username is required"
            showError = true
            return
        }

        guard username.count >= 3 else {
            errorMessage = "Username must be at least 3 characters"
            showError = true
            return
        }

        guard username.count <= 50 else {
            errorMessage = "Username must be less than 50 characters"
            showError = true
            return
        }

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

