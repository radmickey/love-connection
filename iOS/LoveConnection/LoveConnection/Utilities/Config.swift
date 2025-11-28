import Foundation

class Config {
    static let shared = Config()

    private init() {}

    var baseURL: String {
        #if DEBUG
        return getBackendURL(for: "DEBUG_BACKEND_URL") ?? "http://84.252.141.42:8080"
        #else
        return getBackendURL(for: "PRODUCTION_BACKEND_URL") ?? "https://love-couple-connect.duckdns.org"
        #endif
    }

    private func getBackendURL(for key: String) -> String? {
        // Пробуем несколько способов получить URL из Info.plist
        if let path = Bundle.main.path(forResource: "Info", ofType: "plist"),
           let plist = NSDictionary(contentsOfFile: path),
           let url = plist[key] as? String,
           !url.isEmpty {
            return url
        }

        // Альтернативный способ - через Bundle.main.infoDictionary
        if let url = Bundle.main.infoDictionary?[key] as? String, !url.isEmpty {
            return url
        }

        return nil
    }
}
