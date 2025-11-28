import SwiftUI

struct SignUpView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var username = ""
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    TextField("Username", text: $username)
                        .textFieldStyle(.roundedBorder)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                        .submitLabel(.next)

                    TextField("Email", text: $email)
                        .textFieldStyle(.roundedBorder)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                        .submitLabel(.next)

                    SecureField("Password", text: $password)
                        .textFieldStyle(.roundedBorder)
                        .submitLabel(.next)

                    SecureField("Confirm Password", text: $confirmPassword)
                        .textFieldStyle(.roundedBorder)
                        .submitLabel(.done)
                        .onSubmit {
                            if isFormValid {
                                signUp()
                            }
                        }

                    Button(action: signUp) {
                        if isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Sign Up")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isLoading || !isFormValid)
                }
                .padding()

                Spacer()
            }
            .navigationTitle("Sign Up")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
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

    private var isFormValid: Bool {
        !email.isEmpty &&
        !password.isEmpty &&
        !username.isEmpty &&
        password == confirmPassword &&
        password.count >= 6
    }
    
    private func validateForm() -> String? {
        if username.isEmpty {
            return "Username is required"
        }
        
        if username.count < 3 {
            return "Username must be at least 3 characters"
        }
        
        if email.isEmpty {
            return "Email is required"
        }
        
        if !EmailValidator.isValid(email) {
            return "Please enter a valid email address"
        }
        
        if password.isEmpty {
            return "Password is required"
        }
        
        if password.count < 6 {
            return "Password must be at least 6 characters long"
        }
        
        if password != confirmPassword {
            return "Passwords do not match"
        }
        
        return nil
    }

    private func signUp() {
        if let validationError = validateForm() {
            errorMessage = validationError
            showError = true
            return
        }

        isLoading = true
        errorMessage = nil
        showError = false

        Task {
            do {
                let response = try await AuthService.shared.register(email: email, password: password, username: username)
                appState.currentUser = response.user
                appState.isAuthenticated = true
                await appState.loadCurrentPair()
                dismiss()
            } catch {
                errorMessage = ErrorFormatter.userFriendlyMessage(from: error)
                showError = true
            }
            isLoading = false
        }
    }
}

