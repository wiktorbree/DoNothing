
import SwiftUI

struct RulesView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Group {
                        Text("The Challenge")
                            .font(.title2.bold())
                        Text("Practice doing nothing daily for 12 weeks.")
                        
                        Text("Growth")
                            .font(.headline)
                        Text("Starts at 5 minutes. Increases by 5 minutes every week until 60 minutes.")
                        
                        Text("Minimum Rule")
                            .font(.headline)
                        Text("Even on bad days, do the minimum time. No catching up.")
                        
                        Text("Freeze Rule")
                            .font(.headline)
                        Text("If you report a negative experience for 3 days in a row, the time stops increasing for 2 weeks.")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding()
            }
            .navigationTitle("Rules")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}
