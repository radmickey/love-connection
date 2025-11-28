import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        NotificationService.shared.updateDeviceToken(deviceToken)
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        #if !targetEnvironment(simulator)
        print("Failed to register for remote notifications: \(error)")
        #else
        print("Note: Push notifications are not fully supported in simulator")
        #endif
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        print("🔗 Deep link received: \(url.absoluteString)")

        guard url.scheme == "loveconnection" else {
            return false
        }

        if url.host == "add" {
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            if let username = components?.queryItems?.first(where: { $0.name == "username" })?.value {
                print("🔗 Username from deep link: \(username)")
                // Используем NotificationCenter для передачи username в AppState
                NotificationCenter.default.post(name: NSNotification.Name("AddPartnerByUsername"), object: nil, userInfo: ["username": username])
            }
        }

        return true
    }
}

