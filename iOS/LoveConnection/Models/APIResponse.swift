//
//  APIResponse.swift
//  LoveConnection
//
//  Created on 2025-01-27.
//

import Foundation

struct APIResponse<T: Codable>: Codable {
    let success: Bool
    let data: T?
    let message: String?
    let error: String?
}

struct AuthResponse: Codable {
    let token: String
    let refreshToken: String?
    let user: User
}

struct ErrorResponse: Codable {
    let error: String
    let message: String?
}

