import Foundation
import Combine

@MainActor
class AppState: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var currentUser: User?
    @Published var currentPair: Pair?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let authService = AuthService.shared
    private let apiService = APIService.shared

    init() {
        checkAuthenticationStatus()
    }

    func checkAuthenticationStatus() {
        Task {
            if let token = KeychainHelper.shared.getToken() {
                do {
                    let user = try await apiService.getCurrentUser()
                    self.currentUser = user
                    self.isAuthenticated = true
                    await loadCurrentPair()
                } catch {
                    KeychainHelper.shared.deleteToken()
                    self.isAuthenticated = false
                }
            }
        }
    }

    func loadCurrentPair() async {
        do {
            self.currentPair = try await apiService.getCurrentPair()
            if self.currentPair != nil {
                WebSocketService.shared.connect()
            } else {
                WebSocketService.shared.disconnect()
            }
        } catch {
            self.currentPair = nil
            WebSocketService.shared.disconnect()
        }
    }

    func deletePair() async {
        do {
            try await apiService.deletePair()
            self.currentPair = nil
            WebSocketService.shared.disconnect()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func logout() {
        WebSocketService.shared.disconnect()
        KeychainHelper.shared.deleteToken()
        self.isAuthenticated = false
        self.currentUser = nil
        self.currentPair = nil
    }
}

