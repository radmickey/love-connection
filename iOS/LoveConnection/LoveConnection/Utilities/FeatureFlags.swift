import Foundation
import Combine

struct FeatureFlagsResponse: Codable {
    let enableEmailPasswordAuth: Bool
    let enableAppleSignIn: Bool

    enum CodingKeys: String, CodingKey {
        case enableEmailPasswordAuth = "enable_email_password_auth"
        case enableAppleSignIn = "enable_apple_sign_in"
    }
}

@MainActor
class FeatureFlags: ObservableObject {
    static let shared = FeatureFlags()

    @Published var enableEmailPasswordAuth = false
    @Published var enableAppleSignIn = true

    private let cacheKey = "feature_flags_cache"
    private let cacheExpirationKey = "feature_flags_cache_expiration"
    private let cacheDuration: TimeInterval = 3600

    private init() {
        loadCachedFlags()
        Task {
            await fetchFlags()
        }
    }

    func fetchFlags() async {
        do {
            let response: APIResponse<FeatureFlagsResponse> = try await APIService.shared.request(
                APIResponse<FeatureFlagsResponse>.self,
                endpoint: "/api/feature-flags",
                method: "GET"
            )

            if let flags = response.data {
                enableEmailPasswordAuth = flags.enableEmailPasswordAuth
                enableAppleSignIn = flags.enableAppleSignIn
                saveCachedFlags(flags)
            }
        } catch {
            print("Failed to fetch feature flags: \(error)")
        }
    }

    private func loadCachedFlags() {
        guard let data = UserDefaults.standard.data(forKey: cacheKey),
              let expiration = UserDefaults.standard.object(forKey: cacheExpirationKey) as? Date,
              expiration > Date() else {
            return
        }

        if let flags = try? JSONDecoder().decode(FeatureFlagsResponse.self, from: data) {
            enableEmailPasswordAuth = flags.enableEmailPasswordAuth
            enableAppleSignIn = flags.enableAppleSignIn
        }
    }

    private func saveCachedFlags(_ flags: FeatureFlagsResponse) {
        if let data = try? JSONEncoder().encode(flags) {
            UserDefaults.standard.set(data, forKey: cacheKey)
            UserDefaults.standard.set(Date().addingTimeInterval(cacheDuration), forKey: cacheExpirationKey)
        }
    }
}

