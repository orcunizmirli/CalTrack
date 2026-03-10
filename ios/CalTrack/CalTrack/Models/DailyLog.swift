import Foundation
import SwiftData

@Model
final class DailyLog {
    var id: String
    var date: Date
    var totalCalories: Double
    var totalProteinG: Double
    var totalCarbsG: Double
    var totalFatG: Double
    var calorieGoal: Int
    var proteinGoal: Int
    var carbsGoal: Int
    var fatGoal: Int
    var steps: Int
    var activeCaloriesBurned: Double
    var waterMl: Int
    var updatedAt: Date

    init(date: Date = Date()) {
        self.id = UUID().uuidString
        self.date = date.startOfDay
        self.totalCalories = 0
        self.totalProteinG = 0
        self.totalCarbsG = 0
        self.totalFatG = 0
        self.calorieGoal = UserDefaultsManager.shared.dailyCalorieGoal
        self.proteinGoal = UserDefaultsManager.shared.proteinGoal
        self.carbsGoal = UserDefaultsManager.shared.carbsGoal
        self.fatGoal = UserDefaultsManager.shared.fatGoal
        self.steps = 0
        self.activeCaloriesBurned = 0
        self.waterMl = 0
        self.updatedAt = Date()
    }

    var caloriesRemaining: Double {
        Double(calorieGoal) - totalCalories + activeCaloriesBurned
    }

    var calorieProgress: Double {
        guard calorieGoal > 0 else { return 0 }
        return min(totalCalories / Double(calorieGoal), 1.5)
    }

    var proteinProgress: Double {
        guard proteinGoal > 0 else { return 0 }
        return totalProteinG / Double(proteinGoal)
    }

    var carbsProgress: Double {
        guard carbsGoal > 0 else { return 0 }
        return totalCarbsG / Double(carbsGoal)
    }

    var fatProgress: Double {
        guard fatGoal > 0 else { return 0 }
        return totalFatG / Double(fatGoal)
    }
}

@Model
final class WaterEntry {
    var id: String
    var amountMl: Int
    var date: Date
    var createdAt: Date

    init(amountMl: Int, date: Date = Date()) {
        self.id = UUID().uuidString
        self.amountMl = amountMl
        self.date = date.startOfDay
        self.createdAt = Date()
    }
}

@Model
final class WeightLog {
    var id: String
    var weightKg: Double
    var bodyFatPct: Double?
    var date: Date
    var source: String // manual, apple_health
    var createdAt: Date

    init(weightKg: Double, bodyFatPct: Double? = nil, date: Date = Date(), source: String = "manual") {
        self.id = UUID().uuidString
        self.weightKg = weightKg
        self.bodyFatPct = bodyFatPct
        self.date = date.startOfDay
        self.source = source
        self.createdAt = Date()
    }
}
