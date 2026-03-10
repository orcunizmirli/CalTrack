import Foundation

struct AIFoodAnalysisResponse: Codable {
    var items: [AIDetectedFoodItem]
    var totalCalories: Double
    var mealDescription: String
    var confidence: Double
    var processingMs: Int?
}

struct AIDetectedFoodItem: Codable, Identifiable {
    var id: String
    var name: String
    var nameEn: String?
    var portionG: Double
    var calories: Double
    var proteinG: Double
    var carbsG: Double
    var fatG: Double
    var fiberG: Double?
    var confidence: Double

    init(
        id: String = UUID().uuidString,
        name: String,
        nameEn: String? = nil,
        portionG: Double,
        calories: Double,
        proteinG: Double,
        carbsG: Double,
        fatG: Double,
        fiberG: Double? = nil,
        confidence: Double = 0.8
    ) {
        self.id = id
        self.name = name
        self.nameEn = nameEn
        self.portionG = portionG
        self.calories = calories
        self.proteinG = proteinG
        self.carbsG = carbsG
        self.fatG = fatG
        self.fiberG = fiberG
        self.confidence = confidence
    }

    var nutrition: NutritionInfo {
        NutritionInfo(
            calories: calories,
            proteinG: proteinG,
            carbsG: carbsG,
            fatG: fatG,
            fiberG: fiberG ?? 0,
            sugarG: 0
        )
    }
}

struct AIAnalysisRequest {
    var imageData: Data
    var mealType: MealType?
    var additionalContext: String?
}
