import Foundation
import Combine

class WebSocketService: ObservableObject {
    static let shared = WebSocketService()

    @Published var isConnected = false
    @Published var receivedLoveEvent: LoveEvent?

    private var webSocketTask: URLSessionWebSocketTask?
    private var urlSession: URLSession?

    private init() {}

    func connect() {
        guard let token = KeychainHelper.shared.getToken() else {
            return
        }

        let baseURLString = Config.shared.baseURL
        var wsURLString = baseURLString
        if baseURLString.hasPrefix("https://") {
            wsURLString = baseURLString.replacingOccurrences(of: "https://", with: "wss://")
        } else if baseURLString.hasPrefix("http://") {
            wsURLString = baseURLString.replacingOccurrences(of: "http://", with: "ws://")
        }

        guard let wsURL = URL(string: wsURLString + Constants.API.websocket) else {
            return
        }

        var request = URLRequest(url: wsURL)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let session = URLSession(configuration: .default)
        webSocketTask = session.webSocketTask(with: request)
        webSocketTask?.resume()

        isConnected = true
        receiveMessage()
    }

    func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        isConnected = false
    }

    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    self?.handleMessage(text)
                case .data(let data):
                    if let text = String(data: data, encoding: .utf8) {
                        self?.handleMessage(text)
                    }
                @unknown default:
                    break
                }
                self?.receiveMessage()
            case .failure:
                self?.isConnected = false
            }
        }
    }

    private func handleMessage(_ text: String) {
        guard let data = text.data(using: .utf8),
              let event = try? JSONDecoder().decode(WebSocketMessage.self, from: data) else {
            return
        }

        if event.type == "love_event", let loveEvent = event.data {
            DispatchQueue.main.async {
                self.receivedLoveEvent = loveEvent
            }
        }
    }
}

struct WebSocketMessage: Decodable {
    let type: String
    let data: LoveEvent?

    enum CodingKeys: String, CodingKey {
        case type
        case data
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(String.self, forKey: .type)

        if type == "love_event" {
            data = try? container.decode(LoveEvent.self, forKey: .data)
        } else {
            data = nil
        }
    }
}

