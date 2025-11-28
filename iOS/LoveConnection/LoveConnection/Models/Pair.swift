//
//  Pair.swift
//  LoveConnection
//
//  Created on 2025-01-27.
//

import Foundation

struct Pair: Codable, Identifiable {
    let id: UUID
    let user1Id: UUID
    let user2Id: UUID
    let user1: User?
    let user2: User?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case user1Id = "user1_id"
        case user2Id = "user2_id"
        case user1
        case user2
        case createdAt = "created_at"
    }
    
    func getPartner(for userId: UUID) -> User? {
        if user1Id == userId {
            return user2
        } else if user2Id == userId {
            return user1
        }
        return nil
    }
}

