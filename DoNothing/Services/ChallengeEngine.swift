
import Foundation

import SwiftData

struct ChallengeEngine {
    
    // MARK: - API
    
    /// Calculates the challenge context for a given date (usually today).
    /// - Parameters:
    ///   - date: The date to check (will be normalized to start of day)
    ///   - startDate: The start date of the challenge
    ///   - freezeUntilDate: The date until which the challenge is frozen (exclusive, i.e., resumes ON this date?) 
    ///     *Rule: "targetMinutes stays at the value at freeze start... After freezeUntilDate passes, resume"*
    ///     Let's interpret freezeUntilDate as the date normal growth resumes? Or the last day of freeze?
    ///     Rule: "freeze for 2 weeks". "After freeze ends, resume".
    ///     Let's say freeze trigger on Day T. Freeze lasts 14 days. T+1..T+14 are frozen. T+15 resumes.
    ///     So effectively, we subtract (freezeDays) from the elapsed days to calculate the "effective" day index for growth.
    ///   - logs: All past day logs to check for completion status.
    /// - Returns: ChallengeInfo struct
    static func getChallengeInfo(
        for date: Date,
        startDate: Date?,
        freezeUntilDate: Date?,
        logs: [DayLog]
    ) -> ChallengeInfo {
        // Handle not started case
        guard let startDate = startDate else {
             return ChallengeInfo(
                dayIndex: 1, 
                weekIndex: 1, 
                targetMinutes: 5, 
                isFrozen: false, 
                isCompleted: false, 
                freezeUntilDate: nil,
                isStarted: false
            )
        }
        
        let normalizedDate = date.startOfDay
        let normalizedStart = startDate.startOfDay
        
        let daysElapsed = Calendar.current.dateComponents([.day], from: normalizedStart, to: normalizedDate).day ?? 0
        let dayIndex = daysElapsed + 1 // Day 1 is the start date
        
        // Check if finished
        if dayIndex > 84 {
            // Calculate final stats
            let completedDays = logs.filter { $0.status == .completed }.count
            let successThreshold = Int(ceil(0.8 * 84))
            let success = completedDays >= successThreshold
            
            return ChallengeInfo(
                dayIndex: 84, // Cap at 84 for display
                weekIndex: 12,
                targetMinutes: 60,
                isFrozen: false,
                isCompleted: success,
                freezeUntilDate: freezeUntilDate
            )
        }
        
        if dayIndex < 1 {
            // Before start?
            return ChallengeInfo(
                dayIndex: 1, weekIndex: 1, targetMinutes: 5, isFrozen: false, isCompleted: false, freezeUntilDate: nil
            )
        }
        
        // Freeze Logic
        var isFrozen = false
        var effectiveDayIndex = dayIndex
        
        if let freezeUntil = freezeUntilDate?.startOfDay, normalizedDate < freezeUntil {
            isFrozen = true
            // If frozen, we effectively explicitly cap the growth.
            // But how do we know what the specific target was when it froze?
            // "While freeze active, targetMinutes stays at the value at freeze start"
            // The simplest way is to compute what the target would have been on the day the freeze *started*.
            // Freeze start date = freezeUntil - 14 days.
            
            if let freezeStart = Calendar.current.date(byAdding: .day, value: -14, to: freezeUntil) {
                 // The "freeze start" is usually the day AFTER the 3rd bad day.
                 // So the target for the freeze period is the target of the day the freeze triggered (or the day before?)
                 // Rule: "freeze for 2 weeks. During freeze, target time stays constant."
                 // Usually constant at the level of the *current* week when freeze happened.
                 
                 // Let's rely on effective days for calculation.
                 // If we are frozen, we just need to find the week index of the freeze start day.
                 let freezeStartDaysElapsed = Calendar.current.dateComponents([.day], from: normalizedStart, to: freezeStart).day ?? 0
                 let freezeStartDayIndex = freezeStartDaysElapsed + 1 // The day the freeze STARTED (first day of freeze)
                 
                 // If we are ON the freeze start day, or after, but before end.
                 // The target should be based on (freezeStartDayIndex - 1) maybe?
                 // Or just freezeStartDayIndex.
                 
                 effectiveDayIndex = max(1, freezeStartDayIndex)
            }
        } else if freezeUntilDate != nil {
             // Freeze is over.
             // We need to subtract the 14 days from our growth calculation?
             // "After freeze ends, resume weekly increases."
             // This implies the schedule shifts or we just pick up where we left off.
             // If we pick up, then effectiveDayIndex = dayIndex - 14.
             effectiveDayIndex = dayIndex - 14
        }
        
        let weekIndex = Int(ceil(Double(effectiveDayIndex) / 7.0))
        let clampedWeek = max(1, min(12, weekIndex))
        
        let baseTarget = min(defaultTarget(for: clampedWeek), 60)
        
        return ChallengeInfo(
            dayIndex: dayIndex,
            weekIndex: clampedWeek,
            targetMinutes: baseTarget,
            isFrozen: isFrozen,
            isCompleted: false,
            freezeUntilDate: freezeUntilDate
        )
    }
    
    static func defaultTarget(for week: Int) -> Int {
        return min(MAX_MINUTES, INITIAL_MINUTES + (week - 1) * 5)
    }
    
    static let INITIAL_MINUTES = 5
    static let MAX_MINUTES = 60
    
    // Check if we should trigger freeze based on recent logs.
    // Rule: "if for 3 days in a row user reports negative experience (bad/negative)"
    static func shouldTriggerFreeze(logs: [DayLog], currentDate: Date) -> Bool {
        // Filter only completed days with "bad" rating
        // Also they must be consecutive calendar days.
        let badLogs = logs.filter { $0.ratingRaw == LogRating.bad.rawValue }
        
        // We need 3 consecutive days ending roughly yesterday or today.
        // Actually the rule says "if for 3 days in a row... freeze".
        // This check would run after a new log is added.
        
        // Sort by date descending
        let sortedBad = badLogs.sorted { $0.date > $1.date }
        
        guard sortedBad.count >= 3 else { return false }
        
        let last = sortedBad[0]
        let secondLast = sortedBad[1]
        let thirdLast = sortedBad[2]
        
        // Check adjacency
        // log date is normalized.
        let c = Calendar.current
        
        let diff1 = c.dateComponents([.day], from: secondLast.date, to: last.date).day
        let diff2 = c.dateComponents([.day], from: thirdLast.date, to: secondLast.date).day
        
        if diff1 == 1 && diff2 == 1 {
            return true
        }
        
        return false
    }
    static func updateStateAfterLogChange(context: ModelContext) {
        // Fetch necessary data
        let descriptor = FetchDescriptor<ChallengeState>()
        guard let state = try? context.fetch(descriptor).first else { return }
        
        // If already frozen for a long time, maybe we don't need to do anything?
        // But if we edited a log, we might need to TRIGGER a freeze.
        // We won't UN-FREEZE automatically for now to be safe, only check for NEW freeze triggers.
        
        let logDescriptor = FetchDescriptor<DayLog>(sortBy: [SortDescriptor(\DayLog.date, order: .reverse)])
        guard let logs = try? context.fetch(logDescriptor) else { return }
        
        if shouldTriggerFreeze(logs: logs, currentDate: Date()) {
            // Check if we are already frozen covering today?
            let now = Date()
            if let currentUniqueFreeze = state.freezeUntilDate, currentUniqueFreeze > now {
                // Already frozen
            } else {
                // SAFETY: Only freeze if the bad run is actually recent.
                // If I edit a log from 100 days ago, it shouldn't freeze me now.
                // Check if the latest bad log is within reasonable timeframe (e.g. last 7 days)
                let badLogs = logs.filter { $0.ratingRaw == LogRating.bad.rawValue }
                if let latestBad = badLogs.sorted(by: { $0.date > $1.date }).first {
                    let diff = Calendar.current.dateComponents([.day], from: latestBad.date, to: now).day ?? 100
                    if diff > 7 {
                        return // Too old to trigger a new freeze now
                    }
                }
                
                // Apply freeze
                // "freeze for 2 weeks"
                if let twoWeeks = Calendar.current.date(byAdding: .day, value: 14, to: now) {
                    state.freezeUntilDate = twoWeeks
                    try? context.save()
                }
            }
        }
    }
}

struct ChallengeInfo {
    let dayIndex: Int
    let weekIndex: Int
    let targetMinutes: Int
    let isFrozen: Bool
    let isCompleted: Bool
    let freezeUntilDate: Date?
    var isStarted: Bool = true // Default to true for backward compat unless explicitly set false
    
    var periodString: String {
        if !isStarted {
            return "Challenge not started"
        }
        return "Day \(dayIndex)/84 • Week \(weekIndex)/12"
    }
}
