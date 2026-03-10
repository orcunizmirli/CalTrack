import Foundation

final class UserDefaultsManager {
    static let shared = UserDefaultsManager()
    private let defaults = UserDefaults.standard

    private enum Keys {
        static let authToken = "auth_token"
        static let refreshToken = "refresh_token"
        static let userId = "user_id"
        static let onboardingComplete = "onboarding_complete"
        static let hasSubscription = "has_subscription"
        static let unitSystem = "unit_system"
        static let language = "language"
        static let dailyCalorieGoal = "daily_calorie_goal"
        static let proteinGoal = "protein_goal"
        static let carbsGoal = "carbs_goal"
        static let fatGoal = "fat_goal"
    }

    private init() {}

    var authToken: String? {
        get { defaults.string(forKey: Keys.authToken) }
        set { defaults.set(newValue, forKey: Keys.authToken) }
    }

    var refreshToken: String? {
        get { defaults.string(forKey: Keys.refreshToken) }
        set { defaults.set(newValue, forKey: Keys.refreshToken) }
    }

    var userId: String? {
        get { defaults.string(forKey: Keys.userId) }
        set { defaults.set(newValue, forKey: Keys.userId) }
    }

    var unitSystem: String {
        get { defaults.string(forKey: Keys.unitSystem) ?? "metric" }
        set { defaults.set(newValue, forKey: Keys.unitSystem) }
    }

    var language: String {
        get { defaults.string(forKey: Keys.language) ?? "tr" }
        set { defaults.set(newValue, forKey: Keys.language) }
    }

    var dailyCalorieGoal: Int {
        get { defaults.integer(forKey: Keys.dailyCalorieGoal) }
        set { defaults.set(newValue, forKey: Keys.dailyCalorieGoal) }
    }

    var proteinGoal: Int {
        get { defaults.integer(forKey: Keys.proteinGoal) }
        set { defaults.set(newValue, forKey: Keys.proteinGoal) }
    }

    var carbsGoal: Int {
        get { defaults.integer(forKey: Keys.carbsGoal) }
        set { defaults.set(newValue, forKey: Keys.carbsGoal) }
    }

    var fatGoal: Int {
        get { defaults.integer(forKey: Keys.fatGoal) }
        set { defaults.set(newValue, forKey: Keys.fatGoal) }
    }

    func clearAll() {
        let domain = Bundle.main.bundleIdentifier!
        defaults.removePersistentDomain(forName: domain)
    }
}
