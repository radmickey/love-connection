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
            if nsError.domain == "com.apple.AuthenticationServices.AuthorizationError" {
                #if targetEnvironment(simulator)
                errorMessage = "Apple Sign In requires a real device or proper simulator configuration"
                #else
                errorMessage = error.localizedDescription
                #endif
            } else {
                errorMessage = error.localizedDescription
            }
        }
    }
}

