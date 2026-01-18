
import Foundation
import SwiftData

@Model
final class ChallengeState {
    var startDate: Date?
    var freezeUntilDate: Date?
    
    // Using a fixed ID or similar to ensure we treat it as a singleton if needed,
    // though typically we just fetch the first one.
    
    init(startDate: Date? = nil) {
        self.startDate = startDate
    }
    
    var isActive: Bool {
        // Simple logic: if we have a start date, it's active.
        // We might want more complex logic later.
        return true
    }
    
    var isFrozen: Bool {
        guard let freezeDate = freezeUntilDate else { return false }
        return Date() < freezeDate
    }
}
