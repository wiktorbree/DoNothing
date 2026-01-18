import SwiftUI
import SwiftData

struct CompletionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    let targetMinutes: Int
    
    // We need logs and state to show "Day X / Week Y"
    @Query(sort: \DayLog.date, order: .reverse) private var logs: [DayLog]
    @Query private var challengeStates: [ChallengeState]
    
    @State private var rating: LogRating?
    @State private var note: String = ""
    
    var body: some View {
        ZStack {
            Color(uiColor: .systemBackground).edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 32) {
                    Spacer(minLength: 40)
                    
                    // Success Indicator
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 64))
                            .foregroundStyle(.green)
                            .symbolEffect(.bounce, value: true) // Simple animation if supported
                        
                        Text("Session Complete")
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundStyle(.primary)
                    }
                    
                    // Info Card
                    VStack(spacing: 8) {
                        Text(infoString)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                        
                        Text("\(targetMinutes) min")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)
                    }
                    
                    Divider()
                        .padding(.horizontal)
                    
                    // Rating
                    VStack(spacing: 16) {
                        Text("How did it feel?")
                            .font(.headline)
                        
                        HStack(spacing: 16) {
                            RatingButton(title: "Good", value: .good, selection: $rating, color: .green)
                            RatingButton(title: "Hard", value: .hard, selection: $rating, color: .orange)
                            RatingButton(title: "Bad", value: .bad, selection: $rating, color: .red)
                        }
                    }
                    
                    // Note
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Add a note (optional)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(.leading, 4)
                        
                        TextField("Write your thoughts...", text: $note, axis: .vertical)
                            .lineLimit(3...6)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(16)
                            .onChange(of: note) { _, newValue in
                                if newValue.count > 120 {
                                    note = String(newValue.prefix(120))
                                }
                            }
                        
                        Text("\(note.count)/120")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .padding(.trailing, 4)
                    }
                    .padding(.horizontal)
                    
                    Spacer(minLength: 40)
                    
                    // Actions
                    VStack(spacing: 16) {
                        Button {
                            saveLog()
                        } label: {
                            Text("Save Entry")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(saveButtonColor)
                                .cornerRadius(16)
                        }
                        .disabled(rating == nil)
                        
                        Button("Skip Note") {
                            saveLog()
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .opacity(rating != nil && note.isEmpty ? 1 : 0) // Only show if rating selected but note empty? Or always?
                        // Actually "Skip note" implies saving without a note.
                        // But if rating is mandatory, we should just rely on Save.
                        // Prompt said: "Secondary action: 'Skip note' or 'Done' if note is optional"
                        // I'll hide it if rating is nil, essentially it's same as Save but explicit UX for "I don't want to type".
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
                .frame(maxWidth: 500) // iPad constraint
                .frame(maxWidth: .infinity)
            }
        }
        .interactiveDismissDisabled()
    }
    
    var saveButtonColor: Color {
        rating != nil ? .blue : .gray.opacity(0.3)
    }
    
    var infoString: String {
        guard let state = challengeStates.first else { return "Challenge" }
        let info = ChallengeEngine.getChallengeInfo(
            for: Date(),
            startDate: state.startDate,
            freezeUntilDate: state.freezeUntilDate,
            logs: logs
        )
        if info.isStarted {
            return "Day \(info.dayIndex) • Week \(info.weekIndex)"
        } else {
            return "Day 1"
        }
    }
    
    func saveLog() {
        let log = DayLog(
            date: Date().startOfDay,
            targetMinutes: targetMinutes,
            completedMinutes: targetMinutes,
            status: .completed,
            rating: rating,
            note: note.isEmpty ? nil : note
        )
        modelContext.insert(log)
        
        if let state = challengeStates.first {
            if state.startDate == nil {
                state.startDate = Date()
            }
        } else {
             let newState = ChallengeState(startDate: Date())
             modelContext.insert(newState)
        }
        
        dismiss()
    }
}

// Reusing RatingSelectButton style logic but slightly clearer
struct RatingButton: View {
    let title: String
    let value: LogRating
    @Binding var selection: LogRating?
    let color: Color
    
    var body: some View {
        Button {
            selection = value
        } label: {
            VStack(spacing: 8) {
                // Could act icon here if desired
                Text(title)
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(selection == value ? color.opacity(0.2) : Color.gray.opacity(0.1))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(selection == value ? color : Color.clear, lineWidth: 2)
            )
            .cornerRadius(12)
            .foregroundStyle(selection == value ? color : .primary)
        }
    }
}
