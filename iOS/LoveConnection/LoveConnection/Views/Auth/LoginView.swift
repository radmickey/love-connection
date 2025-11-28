import SwiftUI

struct LoginView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var featureFlags = FeatureFlags.shared
    @State private var email = ""
    @State private var password = ""
    @State private var showingSignUp = false
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                Text("Couple Love Connection")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                VStack(spacing: 16) {
                    if featureFlags.enableEmailPasswordAuth {
                        TextField("Email", text: $email)
                            .textFieldStyle(.roundedBorder)
                            .autocapitalization(.none)
                            .keyboardType(.emailAddress)
                            .autocorrectionDisabled()
                            .submitLabel(.next)
                            .onSubmit {
                                // Focus moves to password field
                            }

                        SecureField("Password", text: $password)
                            .textFieldStyle(.roundedBorder)
                            .submitLabel(.go)
                            .onSubmit {
                                if !email.isEmpty && !password.isEmpty {
                                    login()
                                }
                            }

                        Button(action: login) {
                            if isLoading {
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                            } else {
                                Text("Login")
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(isLoading || email.isEmpty || password.isEmpty)
                    }

                    if featureFlags.enableAppleSignIn {
                        AppleSignInButton()

                        #if targetEnvironment(simulator)
                        Text("Note: Apple Sign In requires a real device")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        #endif
                    }

                    if featureFlags.enableEmailPasswordAuth {
                        Button("Don't have an account? Sign up") {
                            showingSignUp = true
                        }
                        .font(.caption)
                    }
                }
                .padding(.horizontal)

                Spacer()
            }
            .sheet(isPresented: $showingSignUp) {
                SignUpView()
            }
            .onTapGesture {
                hideKeyboard()
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                }
            }
        }
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    private func login() {
        if email.isEmpty {
            errorMessage = "Email is required"
            showError = true
            return
        }

        if !EmailValidator.isValid(email) {
            errorMessage = "Please enter a valid email address"
            showError = true
            return
        }

        if password.isEmpty {
            errorMessage = "Password is required"
            showError = true
            return
        }

        isLoading = true
        errorMessage = nil
        showError = false

        Task {
            do {
                let response = try await AuthService.shared.login(email: email, password: password)
                appState.currentUser = response.user
                appState.isAuthenticated = true
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

