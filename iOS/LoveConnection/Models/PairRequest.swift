import Foundation

struct PairRequest: Codable, Identifiable {
    let id: UUID
    let requesterId: UUID
    let requestedId: UUID
    let requester: User?
    let requested: User?
    let status: String
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case requesterId = "requester_id"
        case requestedId = "requested_id"
        case requester
        case requested
        case status
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

