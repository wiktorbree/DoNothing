
import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = HomeViewModel()
    @State private var showTimer = false
    @State private var showCalendar = false
    @State private var showSettings = false
    @State private var showRules = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                if let info = viewModel.challengeInfo {
                    // Header
                    VStack(spacing: 8) {
                        if info.isStarted {
                            Text("Day \(info.dayIndex)")
                                .font(.system(size: 60, weight: .thin))
                            Text("Week \(info.weekIndex)")
                                .font(.title3)
                                .foregroundStyle(.secondary)
                        } else {
                            Text("Ready")
                                .font(.system(size: 50, weight: .thin))
                            Text("to do nothing?")
                                .font(.title3)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.top, 40)
                    
                    // Main Status
                    VStack(spacing: 12) {
                        Text("\(info.targetMinutes)")
                            .font(.system(size: 100, weight: .bold))
                            .contentTransition(.numericText(value: Double(info.targetMinutes)))
                        Text("minutes")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
                    
                    if info.isFrozen {
                        Text("Growth Frozen")
                            .font(.caption)
                            .padding(8)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                    }
                    
                    Spacer()
                    
                    // Action Button
                    if viewModel.canStart {
                        Button {
                            showTimer = true
                        } label: {
                            Text("Start")
                                .font(.title3.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 20)
                                .background(Color.primary)
                                .foregroundStyle(Color(uiColor: .systemBackground))
                                .cornerRadius(16)
                        }
                    } else {
                        VStack {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.largeTitle)
                            Text("Completed for today")
                                .font(.headline)
                        }
                        .foregroundStyle(.secondary)
                        .padding()
                    }
                } else {
                    ProgressView()
                }
                
                Spacer()
                
                // Bottom Nav (Simple H-Stack for iPhone, or proper Tabs)
                // User asked for "iPhone: TabView or NavigationStack". 
                // Using Toolbar or bottom buttons for simplicty and "minimal" feel.
                HStack(spacing: 40) {
                    Button("Calendar") { showCalendar = true }
                    Button("Rules") { showRules = true }
                    Button("Settings") { showSettings = true }
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.bottom, 20)
            }
            .padding()
            .onAppear {
                viewModel.loadData(modelContext: modelContext)
            }
            .navigationDestination(isPresented: $showTimer) {
                if let info = viewModel.challengeInfo {
                    TimerView(targetMinutes: info.targetMinutes)
                }
            }
            .sheet(isPresented: $showCalendar) {
                CalendarView()
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showRules) {
                RulesView()
            }
        }
    }
}
