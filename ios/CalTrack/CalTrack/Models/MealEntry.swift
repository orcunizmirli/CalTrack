import Foundation
import SwiftData

enum MealType: String, Codable, CaseIterable {
    case breakfast = "breakfast"
    case lunch = "lunch"
    case dinner = "dinner"
    case snack = "snack"

    var displayName: String {
        switch self {
        case .breakfast: return "Kahvaltı"
        case .lunch: return "Öğle Yemeği"
        case .dinner: return "Akşam Yemeği"
        case .snack: return "Ara Öğün"
        }
    }

    var icon: String {
        switch self {
        case .breakfast: return "sunrise.fill"
        case .lunch: return "sun.max.fill"
        case .dinner: return "moon.fill"
        case .snack: return "leaf.fill"
        }
    }

    var color: String {
        switch self {
        case .breakfast: return "ctBreakfast"
        case .lunch: return "ctLunch"
        case .dinner: return "ctDinner"
        case .snack: return "ctSnack"
        }
    }
}

@Model
final class MealEntry {
    var id: String
    var foodId: String?
    var foodName: String
    var mealType: String      // breakfast, lunch, dinner, snack
    var date: Date
    var quantityG: Double     // grams
    var calories: Double
    var proteinG: Double
    var carbsG: Double
    var fatG: Double
    var fiberG: Double?
    var photoURL: String?
    var isAIScan: Bool
    var notes: String?
    var createdAt: Date

    init(
        id: String = UUID().uuidString,
        foodId: String? = nil,
        foodName: String,
        mealType: MealType,
        date: Date = Date(),
        quantityG: Double,
        calories: Double,
        proteinG: Double,
        carbsG: Double,
        fatG: Double,
        isAIScan: Bool = false,
        photoURL: String? = nil
    ) {
        self.id = id
        self.foodId = foodId
        self.foodName = foodName
        self.mealType = mealType.rawValue
        self.date = date
        self.quantityG = quantityG
        self.calories = calories
        self.proteinG = proteinG
        self.carbsG = carbsG
        self.fatG = fatG
        self.isAIScan = isAIScan
        self.photoURL = photoURL
        self.createdAt = Date()
    }

    var mealTypeEnum: MealType {
        MealType(rawValue: mealType) ?? .snack
    }
}
