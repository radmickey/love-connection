import Foundation

struct Stats: Codable {
    let totalEvents: Int
    let totalDurationSeconds: Int
    let averageDurationSeconds: Double
    
    enum CodingKeys: String, CodingKey {
        case totalEvents = "total_events"
        case totalDurationSeconds = "total_duration_seconds"
        case averageDurationSeconds = "average_duration_seconds"
    }
    
    var formattedTotalDuration: String {
        let hours = totalDurationSeconds / 3600
        let minutes = (totalDurationSeconds % 3600) / 60
        let seconds = totalDurationSeconds % 60
        
        if hours > 0 {
            return "\(hours) ч \(minutes) мин"
        } else if minutes > 0 {
            return "\(minutes) мин \(seconds) сек"
        }
        return "\(seconds) сек"
    }
}

