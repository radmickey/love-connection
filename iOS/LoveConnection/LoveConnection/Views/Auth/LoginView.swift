import SwiftUI

struct LoginView: View {
    @EnvironmentObject var appState: AppState
    @State private var email = ""
    @State private var password = ""
    @State private var showingSignUp = false
    @State private var errorMessage: String?
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                Text("Love Connection")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                VStack(spacing: 16) {
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

                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
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

                    AppleSignInButton()

                    #if targetEnvironment(simulator)
                    Text("Note: Apple Sign In requires a real device")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    #endif

                    Button("Don't have an account? Sign up") {
                        showingSignUp = true
                    }
                    .font(.caption)
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
        }
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    private func login() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                let response = try await AuthService.shared.login(email: email, password: password)
                appState.currentUser = response.user
                appState.isAuthenticated = true
                await appState.loadCurrentPair()
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}

