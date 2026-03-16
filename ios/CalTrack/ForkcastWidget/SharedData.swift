import Foundation
import os

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
    private static let lock = NSLock()
    private static let logger = Logger(subsystem: "com.forkcast.app", category: "WidgetData")

    static func save(_ data: WidgetData) {
        lock.lock()
        defer { lock.unlock() }

        guard let userDefaults = UserDefaults(suiteName: appGroupID) else {
            logger.error("Failed to access App Group UserDefaults for save")
            return
        }
        do {
            let encoded = try JSONEncoder().encode(data)
            userDefaults.set(encoded, forKey: dataKey)
        } catch {
            logger.error("Failed to encode WidgetData: \(error.localizedDescription)")
        }
    }

    static func load() -> WidgetData {
        lock.lock()
        defer { lock.unlock() }

        guard let userDefaults = UserDefaults(suiteName: appGroupID) else {
            logger.error("Failed to access App Group UserDefaults for load")
            return .placeholder
        }
        guard let data = userDefaults.data(forKey: dataKey) else {
            return .placeholder
        }
        do {
            return try JSONDecoder().decode(WidgetData.self, from: data)
        } catch {
            logger.error("Failed to decode WidgetData: \(error.localizedDescription)")
            return .placeholder
        }
    }

    /// Atomically update widget data — read, modify, write in one locked operation
    static func update(_ transform: (inout WidgetData) -> Void) {
        lock.lock()
        defer { lock.unlock() }

        guard let userDefaults = UserDefaults(suiteName: appGroupID) else {
            logger.error("Failed to access App Group UserDefaults for update")
            return
        }

        var data: WidgetData
        if let raw = userDefaults.data(forKey: dataKey),
           let decoded = try? JSONDecoder().decode(WidgetData.self, from: raw) {
            data = decoded
        } else {
            data = .placeholder
        }

        transform(&data)

        if let encoded = try? JSONEncoder().encode(data) {
            userDefaults.set(encoded, forKey: dataKey)
        }
    }
}
