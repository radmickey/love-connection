import Foundation
import UIKit
import UserNotifications

class NotificationService: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationService()
    
    private var pendingDeviceToken: String?
    private let deviceTokenKey = "pending_device_token"
    
    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        loadPendingDeviceToken()
    }
    
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
            return granted
        } catch {
            return false
        }
    }
    
    func registerForRemoteNotifications() {
        UIApplication.shared.registerForRemoteNotifications()
    }
    
    func updateDeviceToken(_ token: Data) {
        let tokenString = token.map { String(format: "%02.2hhx", $0) }.joined()
        pendingDeviceToken = tokenString
        savePendingDeviceToken(tokenString)
        sendDeviceTokenIfAuthenticated(tokenString)
    }
    
    func sendDeviceTokenIfAuthenticated(_ tokenString: String? = nil) {
        let tokenToSend = tokenString ?? pendingDeviceToken
        
        guard let deviceToken = tokenToSend else {
            return
        }
        
        guard KeychainHelper.shared.getToken() != nil else {
            print("Device token saved, will send after authentication")
            return
        }
        
        Task {
            do {
                let body = try JSONEncoder().encode(["device_token": deviceToken])
                let _: APIResponse<EmptyResponse> = try await APIService.shared.request(
                    APIResponse<EmptyResponse>.self,
                    endpoint: "/api/user/device-token",
                    method: "POST",
                    body: body
                )
                print("Device token updated successfully")
                pendingDeviceToken = nil
                clearPendingDeviceToken()
            } catch {
                print("Failed to update device token: \(error)")
            }
        }
    }
    
    private func savePendingDeviceToken(_ token: String) {
        UserDefaults.standard.set(token, forKey: deviceTokenKey)
    }
    
    private func loadPendingDeviceToken() {
        pendingDeviceToken = UserDefaults.standard.string(forKey: deviceTokenKey)
    }
    
    private func clearPendingDeviceToken() {
        UserDefaults.standard.removeObject(forKey: deviceTokenKey)
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        completionHandler()
    }
}

struct EmptyResponse: Codable {}

