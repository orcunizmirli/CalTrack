import SwiftUI
import SwiftData

@main
struct ForkcastApp: App {
    @StateObject private var appState = AppState()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            UserProfile.self,
            FoodItem.self,
            MealEntry.self,
            DailyLog.self,
            WaterEntry.self,
            WeightLog.self,
            SavedRecipe.self
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .preferredColorScheme(.dark)
                .tint(.ctAccent)
        }
        .modelContainer(sharedModelContainer)
    }
}

@MainActor
class AppState: ObservableObject {
    @Published var isOnboardingComplete: Bool
    @Published var isAuthenticated: Bool
    @Published var hasActiveSubscription: Bool

    init() {
        self.isOnboardingComplete = UserDefaults.standard.bool(forKey: "onboarding_complete")
        self.isAuthenticated = UserDefaultsManager.shared.authToken != nil
        self.hasActiveSubscription = UserDefaults.standard.bool(forKey: "has_subscription")
    }

    func completeOnboarding() {
        isOnboardingComplete = true
        UserDefaults.standard.set(true, forKey: "onboarding_complete")
    }

    func signIn() {
        isAuthenticated = true
    }

    func signOut() {
        isAuthenticated = false
        isOnboardingComplete = false
        UserDefaultsManager.shared.clearAll()
    }
}
