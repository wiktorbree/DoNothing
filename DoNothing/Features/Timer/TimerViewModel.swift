
import Foundation
import SwiftUI

@Observable
class TimerViewModel {
    var targetMinutes: Int
    var timeRemaining: TimeInterval
    var isActive = false
    var isFinished = false
    var isMinimalMode = false
    
    private var endDate: Date?
    private var timer: Timer?
    
    init(targetMinutes: Int) {
        self.targetMinutes = targetMinutes
        self.timeRemaining = TimeInterval(targetMinutes * 60)
    }
    
    func start() {
        guard !isActive else { return }
        
        isActive = true
        // Set end date based on current remaining time
        endDate = Date().addingTimeInterval(timeRemaining)
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.tick()
        }
        
        // Haptic start
        Haptics.shared.play(.light)
    }
    
    // Stop / Abort logic
    func stop(early: Bool) {
        isActive = false
        timer?.invalidate()
        timer = nil
        endDate = nil
        
        if early {
            // Do not mark as finished successfully
            // Just reset or handle failure in view
            // Here we just stop the ticking.
        } else {
            finish()
        }
    }
    
    func tick() {
        guard let end = endDate else { return }
        let remaining = end.timeIntervalSinceNow
        
        if remaining <= 0 {
            stop(early: false)
        } else {
            timeRemaining = remaining
        }
    }
    
    private func finish() {
        isFinished = true
        timeRemaining = 0
        Haptics.shared.notify(.success)
    }
    
    // Called when app comes seamlessly from background
    func syncTime() {
        guard isActive, let end = endDate else { return }
        let remaining = end.timeIntervalSinceNow
        if remaining <= 0 {
            finish()
        } else {
            timeRemaining = remaining
        }
    }
}
