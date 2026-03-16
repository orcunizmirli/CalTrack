import Foundation
import SwiftUI

@MainActor
class FoodSearchViewModel: ObservableObject {
    @Published var searchQuery = ""
    @Published var searchResults: [FoodItem] = []
    @Published var recentFoods: [FoodItem] = []
    @Published var frequentFoods: [FoodItem] = []
    @Published var favoriteFoods: [FoodItem] = []
    @Published var isSearching = false
    @Published var selectedMealType: MealType = .lunch
    @Published var scannedBarcode: String?

    private var searchTask: Task<Void, Never>?

    func search() {
        searchTask?.cancel()

        guard searchQuery.count >= 2 else {
            searchResults = []
            return
        }

        searchTask = Task {
            isSearching = true
            do {
                let results: [FoodSearchResult] = try await APIClient.shared.request(
                    endpoint: APIEndpoints.foodSearch,
                    queryItems: [URLQueryItem(name: "q", value: searchQuery)]
                )
                if !Task.isCancelled {
                    searchResults = results.map { $0.toFoodItem() }
                }
            } catch {
                if !Task.isCancelled {
                    // Use local data as fallback
                    print("Search error: \(error)")
                }
            }
            isSearching = false
        }
    }

    func searchByBarcode(_ code: String) async {
        isSearching = true
        do {
            let result: FoodSearchResult = try await APIClient.shared.request(
                endpoint: "\(APIEndpoints.foodBarcode)/\(code)"
            )
            searchResults = [result.toFoodItem()]
        } catch {
            print("Barcode search error: \(error)")
            searchResults = []
        }
        isSearching = false
    }

    func loadRecent() async {
        do {
            let results: [FoodSearchResult] = try await APIClient.shared.request(
                endpoint: APIEndpoints.foodRecent
            )
            recentFoods = results.map { $0.toFoodItem() }
        } catch {
            print("Load recent error: \(error)")
        }
    }

    func loadFrequent() async {
        do {
            let results: [FoodSearchResult] = try await APIClient.shared.request(
                endpoint: APIEndpoints.foodFrequent
            )
            frequentFoods = results.map { $0.toFoodItem() }
        } catch {
            print("Load frequent error: \(error)")
        }
    }

    func loadFavorites() async {
        do {
            let results: [FoodSearchResult] = try await APIClient.shared.request(
                endpoint: APIEndpoints.foodFavorites
            )
            favoriteFoods = results.map { $0.toFoodItem() }
        } catch {
            print("Load favorites error: \(error)")
        }
    }

    func toggleFavorite(_ food: FoodItem) {
        food.isFavorite.toggle()
        if food.isFavorite {
            food.useCount += 1
            favoriteFoods.insert(food, at: 0)
        } else {
            favoriteFoods.removeAll { $0.id == food.id }
        }
    }
}

struct FoodSearchResult: Codable {
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
    var source: String?

    func toFoodItem() -> FoodItem {
        FoodItem(
            id: id,
            name: name,
            nameTr: nameTr,
            brand: brand,
            barcode: barcode,
            servingSizeG: servingSizeG,
            servingLabel: servingLabel,
            calories: calories,
            proteinG: proteinG,
            carbsG: carbsG,
            fatG: fatG,
            source: source
        )
    }
}
