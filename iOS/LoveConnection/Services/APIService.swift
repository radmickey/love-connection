//
//  APIService.swift
//  LoveConnection
//
//  Created on 2025-01-27.
//

import Foundation

class APIService {
    static let shared = APIService()
    
    private let baseURL = Constants.baseURL
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
            throw APIError.httpError(httpResponse.statusCode)
        }
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(T.self, from: data)
        } catch {
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
    
    // MARK: - Pair
    
    func getCurrentPair() async throws -> Pair {
        let response: APIResponse<Pair> = try await request(APIResponse<Pair>.self, endpoint: Constants.API.pairsCurrent)
        guard let pair = response.data else {
            throw APIError.invalidResponse
        }
        return pair
    }
    
    func createPair(qrCode: String) async throws -> Pair {
        let body = try JSONEncoder().encode(["qr_code": qrCode])
        let response: APIResponse<Pair> = try await request(APIResponse<Pair>.self, endpoint: Constants.API.pairsCreate, method: "POST", body: body)
        guard let pair = response.data else {
            throw APIError.invalidResponse
        }
        return pair
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

