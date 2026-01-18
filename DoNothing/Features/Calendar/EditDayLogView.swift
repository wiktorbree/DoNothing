import SwiftUI
import SwiftData

struct EditDayLogView: View {
    let date: Date
    let existingLog: DayLog?
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var note: String = ""
    @State private var rating: LogRating?
    @State private var status: LogStatus = .missed
    @State private var completedMinutes: Double = 0
    
    init(date: Date, existingLog: DayLog?) {
        self.date = date
        self.existingLog = existingLog
        
        // Initialize state
        // We can't directly assign to State in init easily without using _note = State(initialValue: ...)
        // But better to verify in onAppear or similar if backing data exists,
        // or just use the _ syntax.
        
        let initialNote = existingLog?.note ?? ""
        let initialRating = existingLog?.rating
        let initialStatus = existingLog?.status ?? .missed
        let initialMinutes = Double(existingLog?.completedMinutes ?? 0)
        
        _note = State(initialValue: initialNote)
        _rating = State(initialValue: initialRating)
        _status = State(initialValue: initialStatus)
        _completedMinutes = State(initialValue: initialMinutes)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Status") {
                    Picker("Status", selection: $status) {
                        Text("Completed").tag(LogStatus.completed)
                        Text("Failed").tag(LogStatus.failed)
                        Text("Missed").tag(LogStatus.missed)
                    }
                    .pickerStyle(.segmented)
                }
                
                if status == .completed {
                    Section("Duration") {
                        HStack {
                            Text("Minutes")
                            Spacer()
                            TextField("0", value: $completedMinutes, format: .number)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                }
                
                Section("Rating") {
                    HStack {
                        RatingSelectButton(title: "Good", value: .good, selection: $rating, color: .green)
                        Spacer()
                        RatingSelectButton(title: "Hard", value: .hard, selection: $rating, color: .orange)
                        Spacer()
                        RatingSelectButton(title: "Bad", value: .bad, selection: $rating, color: .red)
                    }
                }
                
                Section("Note") {
                    TextField("Optional note (max 120 chars)", text: $note, axis: .vertical)
                        .lineLimit(3...5)
                        .onChange(of: note) { _, newValue in
                            if newValue.count > 120 {
                                note = String(newValue.prefix(120))
                            }
                        }
                    Text("\(note.count)/120")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
            .navigationTitle("Edit Log")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                }
            }
        }
    }
    
    func save() {
        if let log = existingLog {
            // Update existing
            log.note = note.isEmpty ? nil : note
            log.rating = rating
            log.status = status
            if status == .completed {
                // If completed minutes wasn't touched (0), maybe preserve simpler logic?
                // But user can edit it.
                log.completedMinutes = Int(completedMinutes)
                // If we mark completed but minutes is 0, should we default to target?
                // Let's assume user inputs correct info.
            } else {
                log.completedMinutes = 0
            }
        } else {
            // Create new
            // We need a target minutes value.
            // Since we don't have easy access to the exact historical target calculation here without ChallengeEngine,
            // we can try to guess or just set a default.
            // But wait, creating a log for a past day where none existed (missed)?
            // Default target is 5 or whatever was active.
            // For now, let's use 60 as safe fallback or try to infer.
            // Or better: don't worry too much about targetMinutes for retro-created logs, stick to 5 or 60.
            let log = DayLog(
                date: date.startOfDay,
                targetMinutes: 60, // Placeholder, ideally calculated
                completedMinutes: status == .completed ? Int(completedMinutes) : 0,
                status: status,
                rating: rating,
                note: note.isEmpty ? nil : note
            )
            modelContext.insert(log)
        }
        
        try? modelContext.save()
        
        // Recompute derived state
        ChallengeEngine.updateStateAfterLogChange(context: modelContext)
        
        dismiss()
    }
}

struct RatingSelectButton: View {
    let title: String
    let value: LogRating
    @Binding var selection: LogRating?
    let color: Color
    
    var body: some View {
        Button {
            if selection == value {
                selection = nil
            } else {
                selection = value
            }
        } label: {
            Text(title)
                .font(.subheadline)
                .bold()
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(selection == value ? color : Color.gray.opacity(0.2))
                .foregroundStyle(selection == value ? .white : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
