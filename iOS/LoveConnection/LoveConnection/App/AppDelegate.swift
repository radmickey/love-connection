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

        // Поддержка как custom URL scheme, так и Universal Links
        if url.scheme == "loveconnection" {
            // Custom URL scheme: loveconnection://add?username=...
            if url.host == "add" {
                let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
                if let username = components?.queryItems?.first(where: { $0.name == "username" })?.value {
                    print("🔗 Username from deep link: \(username)")
                    NotificationCenter.default.post(name: NSNotification.Name("AddPartnerByUsername"), object: nil, userInfo: ["username": username])
                }
            }
            return true
        } else if url.scheme == "https" && url.host == "love-couple-connect.duckdns.org" {
            // Universal Link: https://love-couple-connect.duckdns.org/add?username=...
            if url.path == "/add" {
                let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
                if let username = components?.queryItems?.first(where: { $0.name == "username" })?.value {
                    print("🔗 Username from Universal Link: \(username)")
                    NotificationCenter.default.post(name: NSNotification.Name("AddPartnerByUsername"), object: nil, userInfo: ["username": username])
                }
            }
            return true
        }

        return false
    }

    // Обработка Universal Links
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
              let url = userActivity.webpageURL else {
            return false
        }

        print("🔗 Universal Link received: \(url.absoluteString)")

        if url.host == "love-couple-connect.duckdns.org" && url.path == "/add" {
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            if let username = components?.queryItems?.first(where: { $0.name == "username" })?.value {
                print("🔗 Username from Universal Link: \(username)")
                NotificationCenter.default.post(name: NSNotification.Name("AddPartnerByUsername"), object: nil, userInfo: ["username": username])
            }
        }

        return true
    }
}

