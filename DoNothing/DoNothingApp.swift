import SwiftUI
import SwiftData

// Create an AppDelegate to handle orientation locking
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        // iPad always allows all (except maybe upside down depending on preference, but requirement says "unrestricted")
        if UIDevice.current.userInterfaceIdiom == .pad {
            return .all
        }
        // iPhone respects the manager
        return OrientationManager.shared.currentOrientationLock
    }
}

@main
struct DoNothingApp: App {
    // Hook up AppDelegate
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    let container: ModelContainer
    
    init() {
        let schema = Schema([
            ChallengeState.self,
            DayLog.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            container = try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
        
        // Ensure ChallengeState exists
        ensureChallengeStateExists(context: container.mainContext)
    }
    
    func ensureChallengeStateExists(context: ModelContext) {
        let descriptor = FetchDescriptor<ChallengeState>()
        if let count = try? context.fetchCount(descriptor), count == 0 {
            let newState = ChallengeState()
            context.insert(newState)
            try? context.save()
        }
    }
    
    var body: some Scene {
        WindowGroup {
            HomeView()
        }
        .modelContainer(container)
    }
}
