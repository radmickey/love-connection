//
//  User.swift
//  LoveConnection
//
//  Created on 2025-01-27.
//

import Foundation

struct User: Codable, Identifiable {
    let id: UUID
    let email: String?
    let appleId: String?
    let username: String
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case appleId = "apple_id"
        case username
        case createdAt = "created_at"
    }
}

