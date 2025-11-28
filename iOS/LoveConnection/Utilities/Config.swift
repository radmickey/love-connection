import Foundation

class Config {
    static let shared = Config()
    
    private init() {}
    
    var baseURL: String {
        if let url = UserDefaults.standard.string(forKey: "backend_url"), !url.isEmpty {
            return url
        }
        
        #if DEBUG
        if let simulatorIP = getSimulatorIP() {
            return "http://\(simulatorIP):8080"
        }
        return "http://localhost:8080"
        #else
        return "https://api.loveconnection.app"
        #endif
    }
    
    private func getSimulatorIP() -> String? {
        guard let path = Bundle.main.path(forResource: "Info", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: path),
              let ip = plist["BackendURL"] as? String else {
            return nil
        }
        return ip
    }
}

