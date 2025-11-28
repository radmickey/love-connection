import Foundation
import Combine

class FeatureFlags: ObservableObject {
    static let shared = FeatureFlags()

    @Published var enableEmailPasswordAuth: Bool = true
    @Published var enableAppleSignIn: Bool = true

    private init() {
        // Можно загружать из UserDefaults или API
        loadFlags()
    }

    private func loadFlags() {
        // Email/Password auth отключен по умолчанию, только Apple Sign In
        // В будущем можно загружать из UserDefaults или API
        enableEmailPasswordAuth = UserDefaults.standard.object(forKey: "enableEmailPasswordAuth") as? Bool ?? false
        enableAppleSignIn = UserDefaults.standard.object(forKey: "enableAppleSignIn") as? Bool ?? true
    }
}

