import Foundation
import Combine

@MainActor
class AppState: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var currentUser: User?
    @Published var currentPair: Pair?
    @Published var isLoading: Bool = false
    @Published var isCheckingAuth: Bool = true
    @Published var errorMessage: String?
    @Published var needsUsernameSetup: Bool = false
    @Published var pendingUsernameToAdd: String?

    private let authService = AuthService.shared
    private let apiService = APIService.shared

    init() {
        checkAuthenticationStatus()
    }

    func checkAuthenticationStatus() {
        isCheckingAuth = true
        Task {
            if KeychainHelper.shared.getToken() != nil {
                do {
                    let user = try await apiService.getCurrentUser()
                    self.currentUser = user
                    self.isAuthenticated = true
                    await loadCurrentPair()
                    // Request notification permissions and register for remote notifications
                    let granted = await NotificationService.shared.requestAuthorization()
                    if granted {
                        NotificationService.shared.registerForRemoteNotifications()
                    }
                    NotificationService.shared.sendDeviceTokenIfAuthenticated()
                } catch {
                    KeychainHelper.shared.deleteToken()
                    self.isAuthenticated = false
                }
            } else {
                self.isAuthenticated = false
            }
            self.isCheckingAuth = false
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
            await MainActor.run {
                self.currentPair = nil
                WebSocketService.shared.disconnect()
                self.errorMessage = nil
            }
        } catch {
            await MainActor.run {
                errorMessage = ErrorFormatter.userFriendlyMessage(from: error)
            }
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

