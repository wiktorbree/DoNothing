
import Foundation
import SwiftData

@Model
final class DayLog {
    @Attribute(.unique) var date: Date // Normalized to start of day
    var targetMinutes: Int
    var completedMinutes: Int
    var statusRaw: String // "completed", "missed"
    var ratingRaw: String? // "good", "hard", "bad"
    var note: String?
    
    init(date: Date, targetMinutes: Int, completedMinutes: Int = 0, status: LogStatus = .missed, rating: LogRating? = nil, note: String? = nil) {
        self.date = date
        self.targetMinutes = targetMinutes
        self.completedMinutes = completedMinutes
        self.statusRaw = status.rawValue
        self.ratingRaw = rating?.rawValue
        self.note = note
    }
    
    var status: LogStatus {
        get { LogStatus(rawValue: statusRaw) ?? .missed }
        set { statusRaw = newValue.rawValue }
    }
    
    var rating: LogRating? {
        get { ratingRaw.flatMap { LogRating(rawValue: $0) } }
        set { ratingRaw = newValue?.rawValue }
    }
}

enum LogStatus: String, Codable {
    case completed
    case missed
    case failed
}

enum LogRating: String, Codable {
    case good
    case hard
    case bad
}
