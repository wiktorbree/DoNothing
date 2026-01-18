
import SwiftUI
import SwiftData

struct CalendarView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query(sort: \DayLog.date, order: .reverse) private var logs: [DayLog]
    
    let columns = Array(repeating: GridItem(.flexible()), count: 7)
    
    // Generate dates for the current month
    // For simplicity in this challenge context, let's show the current month (or a fixed window).
    // The user requirement says "Calendar must ALWAYS render a normal month grid."
    
    @State private var currentMonth: Date = Date()
    @State private var selectedDay: CalendarDayItem?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Month Header
                    Text(monthString(from: currentMonth))
                        .font(.headline)
                        .padding(.top)
                    
                    LazyVGrid(columns: columns, spacing: 15) {
                        // Weekday headers
                        let days = ["S", "M", "T", "W", "T", "F", "S"]
                        ForEach(0..<days.count, id: \.self) { index in
                            Text(days[index])
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        // Days
                        ForEach(daysInMonth(for: currentMonth)) { item in
                            if let date = item.date {
                                DayCell(date: date, log: log(for: date))
                                    .onTapGesture {
                                        selectedDay = item
                                    }
                            } else {
                                Color.clear.frame(width: 32, height: 32)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("History")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(item: $selectedDay) { item in
                if let date = item.date {
                    DayDetailsView(date: date)
                }
            }
        }
    }
    
    struct CalendarDayItem: Identifiable {
        let id = UUID()
        let date: Date?
    }

    func daysInMonth(for date: Date) -> [CalendarDayItem] {
        let calendar = Calendar.current
        guard let range = calendar.range(of: .day, in: .month, for: date),
              let firstDayOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: date)) else {
            return []
        }
        
        let weekday = calendar.component(.weekday, from: firstDayOfMonth)
        // detailed 1-based index, Sunday is 1
        
        let emptyCount = weekday - 1
        let dayCount = range.count
        
        var days: [CalendarDayItem] = []
        
        // Empty days
        for _ in 0..<emptyCount {
            days.append(CalendarDayItem(date: nil))
        }
        
        // Actual days
        for i in 0..<dayCount {
            if let d = calendar.date(byAdding: .day, value: i, to: firstDayOfMonth) {
                days.append(CalendarDayItem(date: d))
            }
        }
        
        return days
    }
    
    func log(for date: Date) -> DayLog? {
        let start = date.startOfDay
        return logs.first { $0.date == start }
    }
    
    func monthString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
}

struct DayCell: View {
    let date: Date
    let log: DayLog?
    
    var body: some View {
        VStack {
            Text(dayString(from: date))
                .font(.caption)
                .foregroundStyle(isToday ? .blue : .primary)
            
            ZStack {
                Circle()
                    .fill(backgroundColor)
                    .frame(width: 32, height: 32)
                
                if let log = log {
                    statusIcon(for: log)
                }
            }
        }
        .contentShape(Rectangle()) // Make entire cell tappable including spacing if needed, but Circle is clear tap target
    }
    
    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
    
    var backgroundColor: Color {
        if let log = log {
            switch log.status {
            case .completed:
                if log.rating == .bad { return .orange.opacity(0.3) }
                if log.rating == .hard { return .yellow.opacity(0.3) }
                return .green.opacity(0.3)
            case .missed, .failed:
                return .red.opacity(0.1)
            }
        }
        return .gray.opacity(0.1) // Neutral
    }
    
    @ViewBuilder
    func statusIcon(for log: DayLog) -> some View {
        switch log.status {
        case .completed:
            Image(systemName: "checkmark")
                .font(.caption)
                .foregroundStyle(.green)
        case .missed, .failed:
            Image(systemName: "xmark")
                .font(.caption)
                .foregroundStyle(.red)
        }
    }
    
    func dayString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
}
