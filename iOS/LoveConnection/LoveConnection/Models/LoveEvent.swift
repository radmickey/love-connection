//
//  LoveEvent.swift
//  LoveConnection
//
//  Created on 2025-01-27.
//

import Foundation

struct LoveEvent: Codable, Identifiable, Equatable {
    let id: UUID
    let pairId: UUID?
    let senderId: UUID
    let sender: User?
    let durationSeconds: Int
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case pairId = "pair_id"
        case senderId = "sender_id"
        case sender
        case durationSeconds = "duration_seconds"
        case createdAt = "created_at"
    }

    var formattedDuration: String {
        let minutes = durationSeconds / 60
        let seconds = durationSeconds % 60

        if minutes > 0 {
            if seconds > 0 {
                return "\(minutes) мин \(seconds) сек"
            }
            return "\(minutes) мин"
        }
        return "\(seconds) сек"
    }

    static func == (lhs: LoveEvent, rhs: LoveEvent) -> Bool {
        lhs.id == rhs.id
    }
}

