import SwiftUI
import AuthenticationServices

struct AppleSignInButton: View {
    @EnvironmentObject var appState: AppState
    @State private var errorMessage: String?

    var body: some View {
        SignInWithAppleButton(.signIn) { request in
            request.requestedScopes = [.fullName, .email]
        } onCompletion: { result in
            handleSignInResult(result)
        }
        .frame(height: 50)
        .cornerRadius(8)
    }

    private func handleSignInResult(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let identityTokenData = appleIDCredential.identityToken,
                  let identityToken = String(data: identityTokenData, encoding: .utf8),
                  let authorizationCodeData = appleIDCredential.authorizationCode,
                  let authorizationCode = String(data: authorizationCodeData, encoding: .utf8) else {
                errorMessage = "Failed to get Apple ID credentials"
                return
            }

            let username = [appleIDCredential.fullName?.givenName, appleIDCredential.fullName?.familyName]
                .compactMap { $0 }
                .joined(separator: " ")

            Task {
                do {
                    let response = try await AuthService.shared.signInWithApple(
                        identityToken: identityToken,
                        authorizationCode: authorizationCode,
                        username: username.isEmpty ? nil : username
                    )
                    appState.currentUser = response.user
                    appState.isAuthenticated = true
                    await appState.loadCurrentPair()
                } catch {
                    errorMessage = error.localizedDescription
                }
            }

        case .failure(let error):
            let nsError = error as NSError
            #if targetEnvironment(simulator)
            if nsError.domain == "com.apple.AuthenticationServices.AuthorizationError" ||
               nsError.domain == "AKAuthenticationError" {
                print("Note: Apple Sign In is not fully supported in iOS Simulator. Use a real device for testing.")
                errorMessage = nil
                return
            }
            #endif

            if nsError.domain == "com.apple.AuthenticationServices.AuthorizationError" {
                switch nsError.code {
                case 1000:
                    errorMessage = "Authorization was cancelled"
                case 1001:
                    errorMessage = "Authorization failed"
                default:
                    errorMessage = "Apple Sign In error: \(nsError.localizedDescription)"
                }
            } else if nsError.domain == "AKAuthenticationError" {
                switch nsError.code {
                case -7034:
                    #if targetEnvironment(simulator)
                    print("Note: Apple Sign In requires a real device")
                    errorMessage = nil
                    #else
                    errorMessage = "Apple Sign In configuration error"
                    #endif
                default:
                    errorMessage = "Authentication error: \(nsError.localizedDescription)"
                }
            } else {
                errorMessage = error.localizedDescription
            }
        }
    }
}

