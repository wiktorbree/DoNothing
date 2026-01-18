
import Foundation

extension Date {
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }
    
    // Returns true if both dates represent the same calendar day
    func isSameDay(as other: Date) -> Bool {
        Calendar.current.isDate(self, inSameDayAs: other)
    }
    
    func adding(days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: self) ?? self
    }
    
    // Normalize to noon to avoid timezone shift issues at boundaries if needed, 
    // but startOfDay is usually safest for "dates".
}
