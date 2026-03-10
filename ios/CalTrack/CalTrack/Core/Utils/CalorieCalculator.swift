import Foundation

enum Gender: String, Codable, CaseIterable {
    case male = "male"
    case female = "female"

    var displayName: String {
        switch self {
        case .male: return "Erkek"
        case .female: return "Kadın"
        }
    }
}

enum ActivityLevel: String, Codable, CaseIterable {
    case sedentary = "sedentary"
    case light = "light"
    case moderate = "moderate"
    case active = "active"
    case veryActive = "very_active"

    var multiplier: Double {
        switch self {
        case .sedentary: return 1.2
        case .light: return 1.375
        case .moderate: return 1.55
        case .active: return 1.725
        case .veryActive: return 1.9
        }
    }

    var displayName: String {
        switch self {
        case .sedentary: return "Hareketsiz"
        case .light: return "Hafif Aktif"
        case .moderate: return "Orta Aktif"
        case .active: return "Çok Aktif"
        case .veryActive: return "Ekstra Aktif"
        }
    }

    var description: String {
        switch self {
        case .sedentary: return "Masa başı iş, az hareket"
        case .light: return "Haftada 1-3 gün egzersiz"
        case .moderate: return "Haftada 3-5 gün egzersiz"
        case .active: return "Haftada 6-7 gün egzersiz"
        case .veryActive: return "Günde 2 kez antrenman, ağır iş"
        }
    }
}

enum GoalType: String, Codable, CaseIterable {
    case loseWeight = "lose_weight"
    case gainMuscle = "gain_muscle"
    case burnFat = "burn_fat"
    case maintain = "maintain"

    var displayName: String {
        switch self {
        case .loseWeight: return "Kilo Ver"
        case .gainMuscle: return "Kas Kazan"
        case .burnFat: return "Yağ Yak"
        case .maintain: return "Kilo Koru"
        }
    }

    var icon: String {
        switch self {
        case .loseWeight: return "arrow.down.circle.fill"
        case .gainMuscle: return "figure.strengthtraining.traditional"
        case .burnFat: return "flame.fill"
        case .maintain: return "equal.circle.fill"
        }
    }
}

struct CalorieCalculator {

    // MARK: - BMR Calculations

    /// Mifflin-St Jeor equation (default, most accurate for general use)
    static func bmrMifflinStJeor(weightKg: Double, heightCm: Double, age: Int, gender: Gender) -> Double {
        let base = 10.0 * weightKg + 6.25 * heightCm - 5.0 * Double(age)
        switch gender {
        case .male: return base + 5
        case .female: return base - 161
        }
    }

    /// Harris-Benedict equation (revised)
    static func bmrHarrisBenedict(weightKg: Double, heightCm: Double, age: Int, gender: Gender) -> Double {
        switch gender {
        case .male:
            return 88.362 + 13.397 * weightKg + 4.799 * heightCm - 5.677 * Double(age)
        case .female:
            return 447.593 + 9.247 * weightKg + 3.098 * heightCm - 4.330 * Double(age)
        }
    }

    /// Katch-McArdle equation (requires body fat percentage - most accurate)
    static func bmrKatchMcArdle(weightKg: Double, bodyFatPct: Double) -> Double {
        let leanBodyMass = weightKg * (1.0 - bodyFatPct / 100.0)
        return 370.0 + 21.6 * leanBodyMass
    }

    // MARK: - TDEE

    /// Calculate Total Daily Energy Expenditure
    static func tdee(bmr: Double, activityLevel: ActivityLevel) -> Double {
        return bmr * activityLevel.multiplier
    }

    /// Dynamic TDEE with Apple Health data
    static func dynamicTDEE(
        bmr: Double,
        baseActivityLevel: ActivityLevel,
        dailySteps: Int = 0,
        activeCaloriesBurned: Double = 0
    ) -> Double {
        let baseTDEE = bmr * 1.2 // Sedentary base
        let stepCalories = Double(dailySteps) * 0.04
        let totalExtra = stepCalories + activeCaloriesBurned
        return baseTDEE + totalExtra
    }

    // MARK: - Goal-based Calorie Target

    /// Calculate daily calorie target based on goal
    static func dailyCalorieTarget(
        tdee: Double,
        goalType: GoalType,
        weeklyChangeKg: Double = 0.5
    ) -> Int {
        let dailyAdjustment = weeklyChangeKg * 1100.0 / 7.0 * 7.0 / 7.0
        // 1 kg fat ≈ 7700 kcal, so weeklyChangeKg * 7700 / 7 ≈ weeklyChangeKg * 1100/day
        let deficit = weeklyChangeKg * 1100.0

        switch goalType {
        case .loseWeight, .burnFat:
            return max(1200, Int(tdee - deficit))
        case .gainMuscle:
            return Int(tdee + deficit * 0.6) // Lean bulk: smaller surplus
        case .maintain:
            return Int(tdee)
        }
    }

    // MARK: - Macro Distribution

    /// Calculate remaining carbs when protein and fat are set
    static func remainingCarbs(
        dailyCalories: Int,
        proteinGrams: Int,
        fatGrams: Int
    ) -> Int {
        let proteinCalories = proteinGrams * 4
        let fatCalories = fatGrams * 9
        let remainingCalories = dailyCalories - proteinCalories - fatCalories
        return max(0, remainingCalories / 4)
    }

    /// Suggested macro split based on goal
    static func suggestedMacros(
        dailyCalories: Int,
        goalType: GoalType,
        weightKg: Double
    ) -> (protein: Int, carbs: Int, fat: Int) {
        switch goalType {
        case .loseWeight:
            // High protein, moderate fat, lower carbs
            let protein = Int(weightKg * 2.0) // 2g/kg
            let fat = Int(weightKg * 0.8)     // 0.8g/kg
            let carbs = remainingCarbs(dailyCalories: dailyCalories, proteinGrams: protein, fatGrams: fat)
            return (protein, carbs, fat)

        case .gainMuscle:
            // High protein, high carbs, moderate fat
            let protein = Int(weightKg * 2.2) // 2.2g/kg
            let fat = Int(weightKg * 0.9)     // 0.9g/kg
            let carbs = remainingCarbs(dailyCalories: dailyCalories, proteinGrams: protein, fatGrams: fat)
            return (protein, carbs, fat)

        case .burnFat:
            // Very high protein, higher fat, lower carbs
            let protein = Int(weightKg * 2.4) // 2.4g/kg
            let fat = Int(weightKg * 1.0)     // 1g/kg
            let carbs = remainingCarbs(dailyCalories: dailyCalories, proteinGrams: protein, fatGrams: fat)
            return (protein, carbs, fat)

        case .maintain:
            // Balanced
            let protein = Int(weightKg * 1.6) // 1.6g/kg
            let fat = Int(weightKg * 0.8)     // 0.8g/kg
            let carbs = remainingCarbs(dailyCalories: dailyCalories, proteinGrams: protein, fatGrams: fat)
            return (protein, carbs, fat)
        }
    }

    /// Calculate calories from macros
    static func caloriesFromMacros(proteinG: Int, carbsG: Int, fatG: Int) -> Int {
        return proteinG * 4 + carbsG * 4 + fatG * 9
    }
}
