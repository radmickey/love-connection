import Foundation
import AuthenticationServices

class AuthService {
    static let shared = AuthService()
    
    private let apiService = APIService.shared
    
    private init() {}
    
    func register(email: String, password: String, username: String) async throws -> AuthResponse {
        let body = try JSONEncoder().encode([
            "email": email,
            "password": password,
            "username": username
        ])
        
        let response: APIResponse<AuthResponse> = try await apiService.request(
            APIResponse<AuthResponse>.self,
            endpoint: Constants.API.authRegister,
            method: "POST",
            body: body
        )
        
        guard let authResponse = response.data else {
            throw APIError.invalidResponse
        }
        
        KeychainHelper.shared.saveToken(authResponse.token)
        if let refreshToken = authResponse.refreshToken {
            KeychainHelper.shared.saveRefreshToken(refreshToken)
        }
        
        return authResponse
    }
    
    func login(email: String, password: String) async throws -> AuthResponse {
        let body = try JSONEncoder().encode([
            "email": email,
            "password": password
        ])
        
        let response: APIResponse<AuthResponse> = try await apiService.request(
            APIResponse<AuthResponse>.self,
            endpoint: Constants.API.authLogin,
            method: "POST",
            body: body
        )
        
        guard let authResponse = response.data else {
            throw APIError.invalidResponse
        }
        
        KeychainHelper.shared.saveToken(authResponse.token)
        if let refreshToken = authResponse.refreshToken {
            KeychainHelper.shared.saveRefreshToken(refreshToken)
        }
        
        return authResponse
    }
    
    func signInWithApple(identityToken: String, authorizationCode: String, username: String?) async throws -> AuthResponse {
        var body: [String: Any] = [
            "identity_token": identityToken,
            "authorization_code": authorizationCode
        ]
        
        if let username = username {
            body["username"] = username
        }
        
        let bodyData = try JSONSerialization.data(withJSONObject: body)
        
        let response: APIResponse<AuthResponse> = try await apiService.request(
            APIResponse<AuthResponse>.self,
            endpoint: Constants.API.authApple,
            method: "POST",
            body: bodyData
        )
        
        guard let authResponse = response.data else {
            throw APIError.invalidResponse
        }
        
        KeychainHelper.shared.saveToken(authResponse.token)
        if let refreshToken = authResponse.refreshToken {
            KeychainHelper.shared.saveRefreshToken(refreshToken)
        }
        
        return authResponse
    }
}

