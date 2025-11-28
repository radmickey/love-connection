import Foundation

struct FeatureFlagsResponse: Codable {
    let enableEmailPasswordAuth: Bool
    let enableAppleSignIn: Bool
    
    enum CodingKeys: String, CodingKey {
        case enableEmailPasswordAuth = "enable_email_password_auth"
        case enableAppleSignIn = "enable_apple_sign_in"
    }
}

