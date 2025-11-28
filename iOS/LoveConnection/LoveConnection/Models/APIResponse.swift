import Foundation
import Combine

struct APIResponse<T: Codable>: Codable {
    let success: Bool
    let data: T?
    let message: String?
    let error: String?
}

struct AuthResponse: Codable {
    let token: String
    let refreshToken: String?
    let user: User

    enum CodingKeys: String, CodingKey {
        case token
        case refreshToken = "refresh_token"
        case user
    }
}

struct ErrorResponse: Codable {
    let error: String
    let message: String?
}

