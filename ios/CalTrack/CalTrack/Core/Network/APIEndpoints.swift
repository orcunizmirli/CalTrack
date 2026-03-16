import Foundation

enum APIEndpoints {
    // MARK: - Auth
    static let register = "/api/v1/auth/register"
    static let login = "/api/v1/auth/login"
    static let appleAuth = "/api/v1/auth/apple"
    static let googleAuth = "/api/v1/auth/google"
    static let refreshToken = "/api/v1/auth/refresh"
    static let logout = "/api/v1/auth/logout"

    // MARK: - User
    static let userProfile = "/api/v1/users/me"
    static let userGoals = "/api/v1/users/me/goals"
    static let userMacros = "/api/v1/users/me/macros"
    static let userStats = "/api/v1/users/me/stats"

    // MARK: - Foods
    static let foodSearch = "/api/v1/foods/search"
    static let foodDetail = "/api/v1/foods"           // + /:id
    static let foodBarcode = "/api/v1/foods/barcode"   // + /:code
    static let foodCustom = "/api/v1/foods/custom"
    static let foodRecent = "/api/v1/foods/recent"
    static let foodFrequent = "/api/v1/foods/frequent"
    static let foodFavorites = "/api/v1/foods/favorites"

    // MARK: - Meals
    static let mealsDaily = "/api/v1/meals/daily"
    static let meals = "/api/v1/meals"
    static let mealSummary = "/api/v1/meals/summary"

    // MARK: - AI
    static let aiAnalyzeFood = "/api/v1/ai/analyze-food"
    static let aiGenerateRecipes = "/api/v1/ai/generate-recipes"
    static let aiRecipeDetail = "/api/v1/ai/recipes"   // + /:id

    // MARK: - Analytics
    static let analyticsCalories = "/api/v1/analytics/calories"
    static let analyticsMacros = "/api/v1/analytics/macros"
    static let analyticsWeight = "/api/v1/analytics/weight"
    static let analyticsStreak = "/api/v1/analytics/streak"
    static let analyticsMicronutrients = "/api/v1/analytics/micronutrients"

    // MARK: - Health Sync
    static let healthImport = "/api/v1/health-sync/import"
    static let healthExport = "/api/v1/health-sync/export"

    // MARK: - Recipes
    static let savedRecipes = "/api/v1/recipes/saved"

    // MARK: - Water
    static let waterDaily = "/api/v1/water/daily"
    static let water = "/api/v1/water"

    // MARK: - Subscriptions
    static let subscriptionVerify = "/api/v1/subscriptions/verify-receipt"
    static let subscriptionStatus = "/api/v1/subscriptions/status"
}

struct AppConfig {
    #if DEBUG
    static let apiBaseURL = "http://localhost:3000"
    #else
    static let apiBaseURL = "https://api.forkcast.app"
    #endif

    static let openAIAPIKey = "" // Set via environment/config
    static let anthropicAPIKey = "" // Set via environment/config
}
