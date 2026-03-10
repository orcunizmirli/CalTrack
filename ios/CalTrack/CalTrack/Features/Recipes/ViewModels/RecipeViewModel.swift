import Foundation

@MainActor
class RecipeViewModel: ObservableObject {
    @Published var mealType: MealType = .dinner
    @Published var targetCalories: Int = 600
    @Published var preferredIngredients = ""
    @Published var dietaryRestrictions: [String] = []
    @Published var recipes: [RecipeResponse] = []
    @Published var isLoading = false
    @Published var error: String?

    var remainingCalories: Int { max(0, UserDefaultsManager.shared.dailyCalorieGoal - 0) }
    var remainingProtein: Int { max(0, UserDefaultsManager.shared.proteinGoal - 0) }
    var remainingCarbs: Int { max(0, UserDefaultsManager.shared.carbsGoal - 0) }
    var remainingFat: Int { max(0, UserDefaultsManager.shared.fatGoal - 0) }

    func generateRecipes() async {
        isLoading = true
        error = nil

        let ingredients = preferredIngredients
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        let request = RecipeRequest(
            mealType: mealType.rawValue,
            targetCalories: targetCalories,
            ingredients: ingredients.isEmpty ? nil : ingredients,
            dietaryRestrictions: dietaryRestrictions.isEmpty ? nil : dietaryRestrictions,
            proteinTarget: remainingProtein,
            carbsTarget: remainingCarbs,
            fatTarget: remainingFat
        )

        do {
            let result: [RecipeResponse] = try await APIClient.shared.request(
                endpoint: APIEndpoints.aiGenerateRecipes,
                method: .POST,
                body: request
            )
            recipes = result
        } catch {
            self.error = "Tarif oluşturulamadı: \(error.localizedDescription)"
            #if DEBUG
            provideMockRecipes()
            #endif
        }

        isLoading = false
    }

    #if DEBUG
    private func provideMockRecipes() {
        recipes = [
            RecipeResponse(
                id: UUID().uuidString,
                title: "Izgara Tavuk & Sebzeli Kinoa",
                description: "Yüksek proteinli, dengeli bir akşam yemeği",
                ingredients: [
                    RecipeIngredient(name: "Tavuk göğsü", amount: 200, unit: "g"),
                    RecipeIngredient(name: "Kinoa", amount: 80, unit: "g"),
                    RecipeIngredient(name: "Brokoli", amount: 100, unit: "g"),
                    RecipeIngredient(name: "Zeytinyağı", amount: 10, unit: "ml"),
                    RecipeIngredient(name: "Limon suyu", amount: 15, unit: "ml")
                ],
                instructions: [
                    "Kinoayı yıkayıp 2 bardak su ile haşlayın (15 dk)",
                    "Tavuk göğsünü baharatlarla marine edin",
                    "Izgarayı kızdırıp tavuğu her yüzünü 6 dk pişirin",
                    "Brokoliyi buharda 5 dk pişirin",
                    "Tüm malzemeleri tabağa yerleştirip zeytinyağı ve limon ile servis edin"
                ],
                prepTimeMin: 10,
                cookTimeMin: 20,
                servings: 1,
                calories: 520,
                proteinG: 48,
                carbsG: 45,
                fatG: 14,
                tags: ["high-protein", "balanced"]
            ),
            RecipeResponse(
                id: UUID().uuidString,
                title: "Protein Dolu Yumurtalı Wrap",
                description: "Hızlı ve pratik yüksek proteinli tarif",
                ingredients: [
                    RecipeIngredient(name: "Tam buğday lavaş", amount: 1, unit: "adet"),
                    RecipeIngredient(name: "Yumurta", amount: 3, unit: "adet"),
                    RecipeIngredient(name: "Ispanak", amount: 50, unit: "g"),
                    RecipeIngredient(name: "Lor peyniri", amount: 30, unit: "g"),
                    RecipeIngredient(name: "Domates", amount: 50, unit: "g")
                ],
                instructions: [
                    "Yumurtaları çırpıp tavada pişirin",
                    "Ispanağı ekleyip 1 dk soteleyin",
                    "Lavaşı ısıtın",
                    "Yumurtalı karışımı, lor peyniri ve domates dilimleriyle lavaşa sarın"
                ],
                prepTimeMin: 5,
                cookTimeMin: 8,
                servings: 1,
                calories: 450,
                proteinG: 32,
                carbsG: 35,
                fatG: 18,
                tags: ["quick", "high-protein"]
            )
        ]
    }
    #endif
}
