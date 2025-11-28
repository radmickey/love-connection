import Foundation

class Config {
    static let shared = Config()

    private init() {}

    var baseURL: String {
        #if DEBUG
        return getBackendURL(for: "DEBUG_BACKEND_URL") ?? "http://localhost:8080"
        #else
        return getBackendURL(for: "PRODUCTION_BACKEND_URL") ?? "http://84.252.141.42:8080"
        #endif
    }

    private func getBackendURL(for key: String) -> String? {
        guard let path = Bundle.main.path(forResource: "Info", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: path),
              let url = plist[key] as? String,
              !url.isEmpty else {
            return nil
        }
        return url
    }
}
