//
//  APIService.swift
//  LoveConnection
//
//  Created on 2025-01-27.
//

import Foundation

class APIService {
    static let shared = APIService()

    private var baseURL: String {
        Config.shared.baseURL
    }
    private let session: URLSession

    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: configuration)
    }

    private func createRequest(endpoint: String, method: String = "GET", body: Data? = nil) throws -> URLRequest {
        guard let url = URL(string: baseURL + endpoint) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = KeychainHelper.shared.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body = body {
            request.httpBody = body
        }

        return request
    }

    func request<T: Decodable>(_ type: T.Type, endpoint: String, method: String = "GET", body: Data? = nil) async throws -> T {
        let request = try createRequest(endpoint: endpoint, method: method, body: body)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw APIError.serverError(errorResponse.error)
            }
            if let errorDict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errorMessage = errorDict["error"] as? String {
                throw APIError.serverError(errorMessage)
            }
            if !data.isEmpty, let errorString = String(data: data, encoding: .utf8) {
                throw APIError.serverError(errorString)
            }
            throw APIError.httpError(httpResponse.statusCode)
        }

        do {
            let decoder = JSONDecoder()
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            decoder.dateDecodingStrategy = .custom { decoder in
                let container = try decoder.singleValueContainer()
                let dateString = try container.decode(String.self)

                if let date = formatter.date(from: dateString) {
                    return date
                }

                formatter.formatOptions = [.withInternetDateTime]
                if let date = formatter.date(from: dateString) {
                    return date
                }

                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date format: \(dateString)")
            }
            return try decoder.decode(T.self, from: data)
        } catch let decodingError as DecodingError {
            let errorDescription: String
            switch decodingError {
            case .typeMismatch(let type, let context):
                errorDescription = "Type mismatch for \(type) at path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))"
            case .valueNotFound(let type, let context):
                errorDescription = "Value not found for \(type) at path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))"
            case .keyNotFound(let key, let context):
                errorDescription = "Key '\(key.stringValue)' not found at path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))"
            case .dataCorrupted(let context):
                errorDescription = "Data corrupted at path: \(context.codingPath.map { $0.stringValue }.joined(separator: ".")) - \(context.debugDescription)"
            @unknown default:
                errorDescription = "Decoding error: \(decodingError.localizedDescription)"
            }
            print("Decoding error details: \(errorDescription)")
            print("Response data: \(String(data: data, encoding: .utf8) ?? "Unable to decode")")
            throw APIError.decodingError(errorDescription)
        } catch {
            print("Unexpected error: \(error)")
            print("Response data: \(String(data: data, encoding: .utf8) ?? "Unable to decode")")
            throw APIError.decodingError(error.localizedDescription)
        }
    }

    // MARK: - User

    func getCurrentUser() async throws -> User {
        let response: APIResponse<User> = try await request(APIResponse<User>.self, endpoint: Constants.API.userMe)
        guard let user = response.data else {
            throw APIError.invalidResponse
        }
        return user
    }

    func updateUsername(_ username: String) async throws -> User {
        let body = try JSONEncoder().encode(["username": username])
        let response: APIResponse<User> = try await request(APIResponse<User>.self, endpoint: "/api/user/me", method: "PATCH", body: body)
        guard let user = response.data else {
            throw APIError.invalidResponse
        }
        return user
    }

    // MARK: - Pair

    func getCurrentPair() async throws -> Pair? {
        let response: APIResponse<Pair> = try await request(APIResponse<Pair>.self, endpoint: Constants.API.pairsCurrent)
        return response.data
    }

    func deletePair() async throws {
        let _: APIResponse<EmptyResponse> = try await request(APIResponse<EmptyResponse>.self, endpoint: Constants.API.pairsCurrent, method: "DELETE")
    }

    func createPairRequest(qrCode: String? = nil, username: String? = nil) async throws -> PairRequest {
        var bodyDict: [String: String] = [:]
        if let qrCode = qrCode {
            bodyDict["qr_code"] = qrCode
        }
        if let username = username {
            bodyDict["username"] = username
        }
        let body = try JSONEncoder().encode(bodyDict)
        let response: APIResponse<PairRequest> = try await request(APIResponse<PairRequest>.self, endpoint: "/api/pairs/request", method: "POST", body: body)
        guard let request = response.data else {
            throw APIError.invalidResponse
        }
        return request
    }

    func searchUser(username: String) async throws -> User {
        let response: APIResponse<User> = try await request(APIResponse<User>.self, endpoint: "/api/user/search?username=\(username.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? username)")
        guard let user = response.data else {
            throw APIError.invalidResponse
        }
        return user
    }

    func generateInviteLink() async throws -> (link: String, username: String) {
        struct InviteLinkResponse: Codable {
            let link: String
            let username: String
        }
        let response: APIResponse<InviteLinkResponse> = try await request(APIResponse<InviteLinkResponse>.self, endpoint: "/api/user/invite-link")
        guard let data = response.data else {
            throw APIError.invalidResponse
        }
        return (data.link, data.username)
    }

    func respondPairRequest(requestId: UUID, accept: Bool) async throws -> Pair? {
        struct RespondRequest: Codable {
            let requestId: String
            let accept: Bool

            enum CodingKeys: String, CodingKey {
                case requestId = "request_id"
                case accept
            }
        }

        let requestBody = RespondRequest(requestId: requestId.uuidString, accept: accept)
        let body = try JSONEncoder().encode(requestBody)
        let response: APIResponse<Pair> = try await request(APIResponse<Pair>.self, endpoint: "/api/pairs/respond", method: "POST", body: body)
        return response.data
    }

    func getPairRequests() async throws -> [PairRequest] {
        let response: APIResponse<[PairRequest]> = try await request(APIResponse<[PairRequest]>.self, endpoint: "/api/pairs/requests")
        return response.data ?? []
    }

    // MARK: - Love Events

    func sendLove(durationSeconds: Int) async throws -> LoveEvent {
        let body = try JSONEncoder().encode(["duration_seconds": durationSeconds])
        let response: APIResponse<LoveEvent> = try await request(APIResponse<LoveEvent>.self, endpoint: Constants.API.loveSend, method: "POST", body: body)
        guard let event = response.data else {
            throw APIError.invalidResponse
        }
        return event
    }

    func getLoveHistory() async throws -> [LoveEvent] {
        let response: APIResponse<[LoveEvent]> = try await request(APIResponse<[LoveEvent]>.self, endpoint: Constants.API.loveHistory)
        return response.data ?? []
    }

    // MARK: - Stats

    func getStats() async throws -> Stats {
        let response: APIResponse<Stats> = try await request(APIResponse<Stats>.self, endpoint: Constants.API.stats)
        guard let stats = response.data else {
            throw APIError.invalidResponse
        }
        return stats
    }
}

enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case serverError(String)
    case decodingError(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .serverError(let message):
            return message
        case .decodingError(let message):
            return "Decoding error: \(message)"
        }
    }
}

