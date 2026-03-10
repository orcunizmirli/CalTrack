import Foundation
import SwiftData

@Model
final class FoodItem {
    var id: String
    var name: String
    var nameTr: String?
    var brand: String?
    var barcode: String?
    var servingSizeG: Double
    var servingLabel: String?
    var calories: Double
    var proteinG: Double
    var carbsG: Double
    var fatG: Double
    var fiberG: Double?
    var sugarG: Double?
    var saturatedFatG: Double?
    var sodiumMg: Double?
    // Micro nutrients
    var vitaminAMcg: Double?
    var vitaminCMg: Double?
    var vitaminDMcg: Double?
    var vitaminEMg: Double?
    var vitaminKMcg: Double?
    var vitaminB1Mg: Double?
    var vitaminB2Mg: Double?
    var vitaminB3Mg: Double?
    var vitaminB6Mg: Double?
    var vitaminB9Mcg: Double?
    var vitaminB12Mcg: Double?
    var calciumMg: Double?
    var ironMg: Double?
    var magnesiumMg: Double?
    var potassiumMg: Double?
    var zincMg: Double?
    var phosphorusMg: Double?
    var source: String?      // usda, openfoodfacts, turkomp, custom, ai
    var isVerified: Bool
    var isFavorite: Bool
    var lastUsedAt: Date?
    var useCount: Int

    init(
        id: String = UUID().uuidString,
        name: String,
        nameTr: String? = nil,
        brand: String? = nil,
        barcode: String? = nil,
        servingSizeG: Double = 100,
        servingLabel: String? = "100g",
        calories: Double = 0,
        proteinG: Double = 0,
        carbsG: Double = 0,
        fatG: Double = 0,
        source: String? = nil,
        isVerified: Bool = false
    ) {
        self.id = id
        self.name = name
        self.nameTr = nameTr
        self.brand = brand
        self.barcode = barcode
        self.servingSizeG = servingSizeG
        self.servingLabel = servingLabel
        self.calories = calories
        self.proteinG = proteinG
        self.carbsG = carbsG
        self.fatG = fatG
        self.source = source
        self.isVerified = isVerified
        self.isFavorite = false
        self.useCount = 0
    }

    /// Calculate nutrition for a given quantity in grams
    func nutritionFor(grams: Double) -> NutritionInfo {
        let ratio = grams / servingSizeG
        return NutritionInfo(
            calories: calories * ratio,
            proteinG: proteinG * ratio,
            carbsG: carbsG * ratio,
            fatG: fatG * ratio,
            fiberG: (fiberG ?? 0) * ratio,
            sugarG: (sugarG ?? 0) * ratio
        )
    }
}

struct NutritionInfo: Codable {
    var calories: Double
    var proteinG: Double
    var carbsG: Double
    var fatG: Double
    var fiberG: Double
    var sugarG: Double

    static var zero: NutritionInfo {
        NutritionInfo(calories: 0, proteinG: 0, carbsG: 0, fatG: 0, fiberG: 0, sugarG: 0)
    }

    static func + (lhs: NutritionInfo, rhs: NutritionInfo) -> NutritionInfo {
        NutritionInfo(
            calories: lhs.calories + rhs.calories,
            proteinG: lhs.proteinG + rhs.proteinG,
            carbsG: lhs.carbsG + rhs.carbsG,
            fatG: lhs.fatG + rhs.fatG,
            fiberG: lhs.fiberG + rhs.fiberG,
            sugarG: lhs.sugarG + rhs.sugarG
        )
    }
}
