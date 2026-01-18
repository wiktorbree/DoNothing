
import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @AppStorage("reminderTime") private var reminderTime: Double = 3600 * 9 // 9 AM default
    @State private var reminderDate = Date()
    @State private var showingResetAlert = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Reminders") {
                    DatePicker("Daily Reminder", selection: $reminderDate, displayedComponents: .hourAndMinute)
                        .onChange(of: reminderDate) { old, new in
                            updateReminder(new)
                        }
                }
                
                Section("Data") {
                    Button("Export JSON") {
                        exportData()
                    }
                    Button("Reset Challenge", role: .destructive) {
                        showingResetAlert = true
                    }
                }
                
                Section("About") {
                    Text("Version 1.0")
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear {
                // Initialize date from stored double
                let todayStart = Date().startOfDay
                reminderDate = todayStart.addingTimeInterval(reminderTime)
            }
            .alert("Reset Challenge?", isPresented: $showingResetAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    resetChallenge()
                }
            } message: {
                Text("This will delete all history and start over from Day 1.")
            }
        }
    }
    
    func updateReminder(_ date: Date) {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        if let hour = components.hour, let minute = components.minute {
            let seconds = Double(hour * 3600 + minute * 60)
            reminderTime = seconds
            NotificationManager.shared.scheduleDailyReminder(at: components)
        }
    }
    
    func resetChallenge() {
        // Delete all data
        try? modelContext.delete(model: DayLog.self)
        try? modelContext.delete(model: ChallengeState.self)
        
        // Re-init state
        let newState = ChallengeState()
        modelContext.insert(newState)
        
        dismiss()
    }
    
    func exportData() {
        // Simple print/share logic would go here.
        // For now, implementing share sheet is verbose, just a placeholder action.
    }
}
