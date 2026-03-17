import Foundation
import SwiftUI
import SwiftData

/// Represents a recently used meal for display in search results
struct RecentMealItem: Identifiable {
    let id: String
    let foodName: String
    let calories: Double
    let proteinG: Double
    let carbsG: Double
    let fatG: Double
    let quantityG: Double
    let mealType: MealType
    let date: Date
}

@MainActor
class FoodSearchViewModel: ObservableObject {
    @Published var searchQuery = ""
    @Published var searchResults: [FoodItem] = []
    @Published var recentMeals: [RecentMealItem] = []
    @Published var customFoods: [FoodItem] = []
    @Published var recentFoods: [FoodItem] = []
    @Published var frequentFoods: [FoodItem] = []
    @Published var favoriteFoods: [FoodItem] = []
    @Published var isSearching = false
    @Published var selectedMealType: MealType = .lunch
    @Published var scannedBarcode: String?

    private var searchTask: Task<Void, Never>?

    func cancelPendingWork() {
        searchTask?.cancel()
        searchTask = nil
    }

    func search(context: ModelContext? = nil) {
        searchTask?.cancel()

        guard searchQuery.count >= 2 else {
            searchResults = []
            return
        }

        let query = searchQuery
        searchTask = Task {
            isSearching = true

            // Search local custom foods
            var localResults: [FoodItem] = []
            if let context = context {
                let descriptor = FetchDescriptor<FoodItem>(
                    predicate: #Predicate<FoodItem> { $0.source == "custom" },
                    sortBy: [SortDescriptor(\FoodItem.lastUsedAt, order: .reverse)]
                )
                if let allCustom = try? context.fetch(descriptor) {
                    localResults = allCustom.filter { item in
                        let name = (item.nameTr ?? item.name).lowercased()
                        return name.contains(query.lowercased())
                    }
                }
            }

            // Search API
            var apiResults: [FoodItem] = []
            do {
                let results: [FoodSearchResult] = try await APIClient.shared.request(
                    endpoint: APIEndpoints.foodSearch,
                    queryItems: [URLQueryItem(name: "q", value: query)],
                    requiresAuth: false
                )
                if !Task.isCancelled {
                    apiResults = results.map { $0.toFoodItem() }
                }
            } catch {
                if !Task.isCancelled {
                    print("Search error: \(error)")
                }
            }

            if !Task.isCancelled {
                // Replace API results with SwiftData managed objects where they exist
                // so properties like isFavorite are accurate
                if let context = context {
                    let allLocal = (try? context.fetch(FetchDescriptor<FoodItem>())) ?? []
                    let localById = Dictionary(allLocal.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
                    apiResults = apiResults.map { localById[$0.id] ?? $0 }
                    // Remove duplicates already in localResults
                    let localIds = Set(localResults.map(\.id))
                    apiResults = apiResults.filter { !localIds.contains($0.id) }
                }
                searchResults = localResults + apiResults
            }
            isSearching = false
        }
    }

    func searchByBarcode(_ code: String) async {
        isSearching = true
        do {
            let result: FoodSearchResult = try await APIClient.shared.request(
                endpoint: "\(APIEndpoints.foodBarcode)/\(code)",
                requiresAuth: false
            )
            searchResults = [result.toFoodItem()]
        } catch {
            print("Barcode search error: \(error)")
            searchResults = []
        }
        isSearching = false
    }

    func loadRecentFromLocal(context: ModelContext) {
        let descriptor = FetchDescriptor<MealEntry>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        guard let entries = try? context.fetch(descriptor) else { return }

        // Deduplicate by foodName, keep the most recent entry per food
        var seen = Set<String>()
        var items: [RecentMealItem] = []
        for entry in entries {
            let key = entry.foodName
            guard !seen.contains(key) else { continue }
            seen.insert(key)
            items.append(RecentMealItem(
                id: entry.id,
                foodName: entry.foodName,
                calories: entry.calories,
                proteinG: entry.proteinG,
                carbsG: entry.carbsG,
                fatG: entry.fatG,
                quantityG: entry.quantityG,
                mealType: MealType(rawValue: entry.mealType) ?? .snack,
                date: entry.createdAt
            ))
        }
        recentMeals = items
    }

    func loadCustomFoods(context: ModelContext) {
        var descriptor = FetchDescriptor<FoodItem>(
            predicate: #Predicate<FoodItem> { $0.source == "custom" },
            sortBy: [SortDescriptor(\.lastUsedAt, order: .reverse)]
        )
        descriptor.fetchLimit = 50
        customFoods = (try? context.fetch(descriptor)) ?? []
    }

    func loadFavorites(context: ModelContext) {
        let descriptor = FetchDescriptor<FoodItem>(
            predicate: #Predicate<FoodItem> { $0.isFavorite == true },
            sortBy: [SortDescriptor(\.lastUsedAt, order: .reverse)]
        )
        favoriteFoods = (try? context.fetch(descriptor)) ?? []
    }

    func toggleFavorite(_ food: FoodItem, context: ModelContext) {
        // Check if food already exists in SwiftData
        let descriptor = FetchDescriptor<FoodItem>()
        let existingFood = (try? context.fetch(descriptor))?.first { $0.id == food.id }

        if let existingFood {
            existingFood.isFavorite.toggle()
            existingFood.lastUsedAt = Date()
            if existingFood.isFavorite {
                favoriteFoods.insert(existingFood, at: 0)
            } else {
                favoriteFoods.removeAll { $0.id == existingFood.id }
            }
        } else {
            // Insert new food into SwiftData as favorite
            food.isFavorite = true
            food.lastUsedAt = Date()
            food.useCount += 1
            context.insert(food)
            favoriteFoods.insert(food, at: 0)
        }
    }
}

/// Prisma returns Decimal fields as strings, so we need a flexible decoder
struct FlexibleDouble: Codable {
    let value: Double

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let d = try? container.decode(Double.self) {
            value = d
        } else if let s = try? container.decode(String.self), let d = Double(s) {
            value = d
        } else if let i = try? container.decode(Int.self) {
            value = Double(i)
        } else {
            value = 0
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }
}

struct FoodSearchResult: Codable {
    var id: String
    var name: String
    var nameTr: String?
    var brand: String?
    var barcode: String?
    var servingSizeG: FlexibleDouble
    var servingLabel: String?
    var calories: FlexibleDouble
    var proteinG: FlexibleDouble
    var carbsG: FlexibleDouble
    var fatG: FlexibleDouble
    var fiberG: FlexibleDouble?
    var source: String?

    func toFoodItem() -> FoodItem {
        FoodItem(
            id: id,
            name: name,
            nameTr: nameTr,
            brand: brand,
            barcode: barcode,
            servingSizeG: servingSizeG.value,
            servingLabel: servingLabel,
            calories: calories.value,
            proteinG: proteinG.value,
            carbsG: carbsG.value,
            fatG: fatG.value,
            source: source
        )
    }
}
