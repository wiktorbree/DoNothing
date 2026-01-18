
import SwiftUI
import SwiftData

struct TimerView: View {
    @State private var viewModel: TimerViewModel
    @Environment(\.scenePhase) var scenePhase
    @Environment(\.dismiss) var dismiss
    
    @Environment(\.modelContext) var modelContext
    @State private var showingStopAlert = false
    
    // For NavigationStack pop
    @State private var showCompletion = false
    
    init(targetMinutes: Int) {
        _viewModel = State(initialValue: TimerViewModel(targetMinutes: targetMinutes))
    }
    
    func handleStop() {
        showingStopAlert = true
    }
    
    func confirmStop() {
        viewModel.stop(early: true)
        
        // Log failed session
        let log = DayLog(
            date: Date().startOfDay,
            targetMinutes: viewModel.targetMinutes,
            completedMinutes: 0, // Incomplete
            status: .failed,
            note: "Session interrupted"
        )
        modelContext.insert(log)
        
        dismiss()
    }
    
    var body: some View {
        ZStack {
            Color(uiColor: .systemBackground).edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    withAnimation {
                        viewModel.isMinimalMode.toggle()
                    }
                }
            
            VStack {
                Spacer()
                
                // Timer Display
                Text(timeString(from: viewModel.timeRemaining))
                    .font(.system(size: 100, weight: .bold, design: .monospaced)) // Large typography
                    .contentTransition(.numericText(value: viewModel.timeRemaining))
                    .padding()
                
                Spacer()
                
                // Controls
                if !viewModel.isMinimalMode {
                    Button(role: .destructive) {
                        handleStop()
                    } label: {
                        Text("Stop Session")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 16)
                            .background(Color.red.opacity(0.8))
                            .clipShape(Capsule())
                    }
                    .padding(.bottom, 50)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            viewModel.start()
        }
        .onChange(of: viewModel.isFinished) { old, finished in
            if finished {
                showCompletion = true
            }
        }
        .fullScreenCover(isPresented: $showCompletion, onDismiss: {
            dismiss() // Go back to Home after completion flow
        }) {
            CompletionView(targetMinutes: viewModel.targetMinutes)
        }
        .alert("Stop Session?", isPresented: $showingStopAlert) {
            Button("Resume", role: .cancel) { }
            Button("Stop & Fail", role: .destructive) {
                confirmStop()
            }
        } message: {
            Text("Stopping now will mark today as incomplete.")
        }
        .onAppear {
            OrientationManager.setLocked(false) // Allow rotation
        }
        .onDisappear {
            OrientationManager.setLocked(true) // Lock back to portrait
        }
    }
    
    func timeString(from interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
