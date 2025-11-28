import SwiftUI
import AuthenticationServices

struct AppleSignInButton: View {
    @EnvironmentObject var appState: AppState
    @State private var errorMessage: String?
    @State private var showError = false

    var body: some View {
        VStack {
            SignInWithAppleButton(.signIn) { request in
                print("🔵🔵🔵 Apple Sign In button tapped - request handler called")
                request.requestedScopes = [.fullName, .email]
                print("🔵 Requested scopes set: fullName, email")
            } onCompletion: { result in
                print("🔵🔵🔵 Apple Sign In completion handler called with result: \(result)")
                handleSignInResult(result)
            }
            .frame(height: 50)
            .frame(maxWidth: .infinity, alignment: .center)
            .cornerRadius(8)

            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.top, 4)
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            if let errorMessage = errorMessage {
                Text(errorMessage)
            }
        }
    }

    private func handleSignInResult(_ result: Result<ASAuthorization, Error>) {
        print("🔵 handleSignInResult called with result: \(result)")
        switch result {
        case .success(let authorization):
            print("🔵 Authorization successful")
            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                print("❌ Failed to cast credential to ASAuthorizationAppleIDCredential")
                errorMessage = "Failed to get Apple ID credentials"
                showError = true
                return
            }

            guard let identityTokenData = appleIDCredential.identityToken,
                  let identityToken = String(data: identityTokenData, encoding: .utf8) else {
                print("❌ Failed to get identity token")
                errorMessage = "Failed to get identity token"
                showError = true
                return
            }

            guard let authorizationCodeData = appleIDCredential.authorizationCode,
                  let authorizationCode = String(data: authorizationCodeData, encoding: .utf8) else {
                print("❌ Failed to get authorization code")
                errorMessage = "Failed to get authorization code"
                showError = true
                return
            }

            print("✅ Got credentials, proceeding with sign in")

            let username = [appleIDCredential.fullName?.givenName, appleIDCredential.fullName?.familyName]
                .compactMap { $0 }
                .joined(separator: " ")

            let userIdentifier = appleIDCredential.user
            print("🔵 User identifier: \(userIdentifier)")

            Task {
                do {
                    print("🔵 Calling AuthService.signInWithApple...")
                    let response = try await AuthService.shared.signInWithApple(
                        identityToken: identityToken,
                        authorizationCode: authorizationCode,
                        userIdentifier: userIdentifier,
                        username: username.isEmpty ? nil : username
                    )
                    print("✅ Sign in successful, user: \(response.user.username)")
                    appState.currentUser = response.user
                    appState.isAuthenticated = true

                    // Проверяем, нужно ли установить username
                    if response.needsUsername == true {
                        appState.needsUsernameSetup = true
                    } else {
                        await appState.loadCurrentPair()
                        NotificationService.shared.sendDeviceTokenIfAuthenticated()
                    }
                } catch {
                    print("❌ Sign in error: \(error)")
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }

        case .failure(let error):
            print("❌ Apple Sign In failed: \(error)")
            let nsError = error as NSError
            print("   Domain: \(nsError.domain), Code: \(nsError.code)")

            #if targetEnvironment(simulator)
            if nsError.domain == "com.apple.AuthenticationServices.AuthorizationError" ||
               nsError.domain == "AKAuthenticationError" {
                print("⚠️  Note: Apple Sign In is not fully supported in iOS Simulator. Use a real device for testing.")
                errorMessage = "Apple Sign In requires a real device"
                showError = true
                return
            }
            #endif

            if nsError.domain == "com.apple.AuthenticationServices.AuthorizationError" {
                switch nsError.code {
                case 1000:
                    print("   User cancelled authorization")
                    errorMessage = "Authorization was cancelled"
                    showError = true
                case 1001:
                    print("   Authorization failed")
                    errorMessage = "Authorization failed"
                    showError = true
                default:
                    print("   Unknown authorization error")
                    errorMessage = "Apple Sign In error: \(nsError.localizedDescription)"
                    showError = true
                }
            } else if nsError.domain == "AKAuthenticationError" {
                switch nsError.code {
                case -7034:
                    #if targetEnvironment(simulator)
                    print("⚠️  Note: Apple Sign In requires a real device")
                    errorMessage = "Apple Sign In requires a real device"
                    #else
                    errorMessage = "Apple Sign In configuration error. Check entitlements."
                    #endif
                    showError = true
                default:
                    errorMessage = "Authentication error: \(nsError.localizedDescription)"
                    showError = true
                }
            } else {
                errorMessage = "Error: \(error.localizedDescription)"
                showError = true
            }
        }
    }
}

