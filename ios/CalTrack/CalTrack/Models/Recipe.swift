import Foundation
import SwiftData

struct RecipeIngredient: Codable {
    var name: String
    var amount: Double
    var unit: String
}

struct RecipeRequest: Codable {
    var mealType: String
    var targetCalories: Int
    var ingredients: [String]?       // Preferred ingredients
    var dietaryRestrictions: [String]? // vegan, gluten-free, etc.
    var proteinTarget: Int?
    var carbsTarget: Int?
    var fatTarget: Int?
}

struct RecipeResponse: Codable, Identifiable {
    var id: String
    var title: String
    var description: String
    var ingredients: [RecipeIngredient]
    var instructions: [String]
    var prepTimeMin: Int
    var cookTimeMin: Int
    var servings: Int
    var calories: Double
    var proteinG: Double
    var carbsG: Double
    var fatG: Double
    var tags: [String]
    var photoURL: String?
}

@Model
final class SavedRecipe {
    var id: String
    var title: String
    var recipeDescription: String
    var ingredientsJSON: Data    // Encoded [RecipeIngredient]
    var instructionsJSON: Data   // Encoded [String]
    var prepTimeMin: Int
    var cookTimeMin: Int
    var servings: Int
    var calories: Double
    var proteinG: Double
    var carbsG: Double
    var fatG: Double
    var tags: [String]
    var photoURL: String?
    var savedAt: Date

    init(from response: RecipeResponse) {
        self.id = response.id
        self.title = response.title
        self.recipeDescription = response.description
        self.ingredientsJSON = (try? JSONEncoder().encode(response.ingredients)) ?? Data()
        self.instructionsJSON = (try? JSONEncoder().encode(response.instructions)) ?? Data()
        self.prepTimeMin = response.prepTimeMin
        self.cookTimeMin = response.cookTimeMin
        self.servings = response.servings
        self.calories = response.calories
        self.proteinG = response.proteinG
        self.carbsG = response.carbsG
        self.fatG = response.fatG
        self.tags = response.tags
        self.photoURL = response.photoURL
        self.savedAt = Date()
    }

    var ingredients: [RecipeIngredient] {
        (try? JSONDecoder().decode([RecipeIngredient].self, from: ingredientsJSON)) ?? []
    }

    var instructions: [String] {
        (try? JSONDecoder().decode([String].self, from: instructionsJSON)) ?? []
    }
}
