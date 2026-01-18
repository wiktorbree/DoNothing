import SwiftUI
import SwiftData

struct DayDetailsView: View {
    let date: Date
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var isEditing = false
    
    // To refresh the view after edit, we rely on SwiftData observation.
    // For simplicity, we can query for the log in this view using the date.
    
    @Query private var logs: [DayLog]
    
    init(date: Date) {
        self.date = date
    }
    
    var effectiveLog: DayLog? {
        logs.first { $0.date == date.startOfDay }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text(dateString)
                            .font(.title2)
                            .bold()
                        Text(statusString)
                            .font(.headline)
                            .foregroundStyle(statusColor)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                            .background(statusColor.opacity(0.1))
                            .clipShape(Capsule())
                    }
                    .padding(.top)
                    
                    Divider()
                    
                    // Stats
                    HStack(spacing: 40) {
                        StatView(label: "Target", value: "\(effectiveLog?.targetMinutes ?? 0)m")
                        StatView(label: "Completed", value: "\(effectiveLog?.completedMinutes ?? 0)m")
                    }
                    
                    Divider()
                    
                    // Rating
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Rating")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        
                        if let rating = effectiveLog?.rating {
                            RatingPill(rating: rating)
                        } else {
                            Text("No rating")
                                .italic()
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    
                    // Note
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Note")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        
                        Text(effectiveLog?.note ?? "No note entered.")
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.gray.opacity(0.05))
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if isPastDay {
                        Button("Edit") { isEditing = true }
                    }
                }
            }
            .sheet(isPresented: $isEditing) {
                EditDayLogView(date: date, existingLog: effectiveLog)
            }
        }
    }
    
    var dateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter.string(from: date)
    }
    
    var statusString: String {
        guard let log = effectiveLog else {
            // Need to determine if it's future or missed/not started
            if date.startOfDay > Date().startOfDay {
                return "Future"
            } else {
                return "No Entry" // Treated as Missed effectively
            }
        }
        return log.statusRaw.capitalized
    }
    
    var statusColor: Color {
        guard let log = effectiveLog else { return .secondary }
        switch log.status {
        case .completed: return .green
        case .failed: return .red
        case .missed: return .orange
        }
    }
    
    var isPastDay: Bool {
        date.startOfDay < Date().startOfDay
    }
}

struct StatView: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3)
                .bold()
        }
    }
}

struct RatingPill: View {
    let rating: LogRating
    
    var color: Color {
        switch rating {
        case .good: return .green
        case .hard: return .orange // Or yellow
        case .bad: return .red
        }
    }
    
    var body: some View {
        Text(rating.rawValue.capitalized)
            .font(.subheadline)
            .bold()
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(color)
            .clipShape(Capsule())
    }
}
