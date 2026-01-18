
import Foundation
import SwiftData
import SwiftUI

@Observable
class HomeViewModel {
    var challengeState: ChallengeState?
    var todayLog: DayLog?
    var challengeInfo: ChallengeInfo?
    
    // Derived UI state
    var canStart: Bool {
        guard let log = todayLog else { return true }
        return log.status != .completed
    }
    
    func loadData(modelContext: ModelContext) {
        // Fetch singleton state
        if let state = try? modelContext.fetch(FetchDescriptor<ChallengeState>()).first {
            self.challengeState = state
        }
        
        // Fetch today's log
        let today = Date().startOfDay
        let logDescriptor = FetchDescriptor<DayLog>(predicate: #Predicate { $0.date == today })
        self.todayLog = try? modelContext.fetch(logDescriptor).first
        
        // Fetch all logs for stats/engine
        let allLogs = (try? modelContext.fetch(FetchDescriptor<DayLog>())) ?? []
        
        if let state = challengeState {
            self.challengeInfo = ChallengeEngine.getChallengeInfo(
                for: Date(),
                startDate: state.startDate,
                freezeUntilDate: state.freezeUntilDate,
                logs: allLogs
            )
        }
    }
}
