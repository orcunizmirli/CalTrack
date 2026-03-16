import Foundation

/// Shared data container for App Group communication between main app and widgets
struct WidgetData: Codable {
    var caloriesConsumed: Double
    var calorieGoal: Int
    var caloriesBurned: Double
    var proteinG: Double
    var proteinGoal: Int
    var carbsG: Double
    var carbsGoal: Int
    var fatG: Double
    var fatGoal: Int
    var waterMl: Int
    var waterGoal: Int
    var lastUpdated: Date

    static var placeholder: WidgetData {
        WidgetData(
            caloriesConsumed: 1200,
            calorieGoal: 2000,
            caloriesBurned: 350,
            proteinG: 80,
            proteinGoal: 150,
            carbsG: 120,
            carbsGoal: 250,
            fatG: 40,
            fatGoal: 70,
            waterMl: 1500,
            waterGoal: 2500,
            lastUpdated: Date()
        )
    }
}

enum WidgetDataManager {
    static let appGroupID = "group.com.forkcast.app"
    private static let dataKey = "widget_data"

    static func save(_ data: WidgetData) {
        guard let userDefaults = UserDefaults(suiteName: appGroupID) else { return }
        if let encoded = try? JSONEncoder().encode(data) {
            userDefaults.set(encoded, forKey: dataKey)
        }
    }

    static func load() -> WidgetData {
        guard let userDefaults = UserDefaults(suiteName: appGroupID),
              let data = userDefaults.data(forKey: dataKey),
              let decoded = try? JSONDecoder().decode(WidgetData.self, from: data) else {
            return .placeholder
        }
        return decoded
    }
}
