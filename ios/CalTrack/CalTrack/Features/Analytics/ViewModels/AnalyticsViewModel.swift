import Foundation

struct CalorieDayData: Decodable, Identifiable {
    let date: Date
    let calories: Double
    var id: Date { date }
}

struct MacroDayData: Decodable, Identifiable {
    let date: Date
    let proteinG: Double
    let carbsG: Double
    let fatG: Double
    var id: Date { date }
}

struct WeightDayData: Decodable, Identifiable {
    let id: String
    let date: Date
    let weightKg: Double
    let bodyFatPct: Double?
}

struct StreakData: Decodable {
    let currentStreak: Int
    let longestStreak: Int
}

@MainActor
class AnalyticsViewModel: ObservableObject {
    @Published var calorieData: [CalorieDayData] = []
    @Published var macroData: [MacroDayData] = []
    @Published var weightData: [WeightDayData] = []
    @Published var streak = StreakData(currentStreak: 0, longestStreak: 0)
    @Published var isLoading = false
    @Published var calorieGoal: Double = 2100

    private let apiClient = APIClient.shared

    func loadData(range: AnalyticsRange) async {
        isLoading = true
        defer { isLoading = false }

        let rangeParam = switch range {
        case .week: "week"
        case .month: "month"
        case .threeMonths: "3months"
        }

        // Load calorie goal from UserDefaults
        calorieGoal = Double(UserDefaultsManager.shared.dailyCalorieGoal)

        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.loadCalories(range: rangeParam) }
            group.addTask { await self.loadMacros(range: rangeParam) }
            group.addTask { await self.loadWeight(range: rangeParam) }
            group.addTask { await self.loadStreak() }
        }
    }

    private func loadCalories(range: String) async {
        do {
            let data: [CalorieDayData] = try await apiClient.request(
                endpoint: APIEndpoints.analyticsCalories,
                queryItems: [URLQueryItem(name: "range", value: range)]
            )
            calorieData = data
        } catch {
            print("Kalori verisi yüklenemedi: \(error)")
        }
    }

    private func loadMacros(range: String) async {
        do {
            let data: [MacroDayData] = try await apiClient.request(
                endpoint: APIEndpoints.analyticsMacros,
                queryItems: [URLQueryItem(name: "range", value: range)]
            )
            macroData = data
        } catch {
            print("Makro verisi yüklenemedi: \(error)")
        }
    }

    private func loadWeight(range: String) async {
        do {
            let data: [WeightDayData] = try await apiClient.request(
                endpoint: APIEndpoints.analyticsWeight,
                queryItems: [URLQueryItem(name: "range", value: range)]
            )
            weightData = data
        } catch {
            print("Kilo verisi yüklenemedi: \(error)")
        }
    }

    private func loadStreak() async {
        do {
            let data: StreakData = try await apiClient.request(
                endpoint: APIEndpoints.analyticsStreak
            )
            streak = data
        } catch {
            print("Seri verisi yüklenemedi: \(error)")
        }
    }

    // Computed averages for macro trend view
    var avgProtein: Double {
        guard !macroData.isEmpty else { return 0 }
        return macroData.map(\.proteinG).reduce(0, +) / Double(macroData.count)
    }

    var avgCarbs: Double {
        guard !macroData.isEmpty else { return 0 }
        return macroData.map(\.carbsG).reduce(0, +) / Double(macroData.count)
    }

    var avgFat: Double {
        guard !macroData.isEmpty else { return 0 }
        return macroData.map(\.fatG).reduce(0, +) / Double(macroData.count)
    }

    var avgCalories: Double {
        guard !calorieData.isEmpty else { return 0 }
        return calorieData.map(\.calories).reduce(0, +) / Double(calorieData.count)
    }

    var weightChange: Double? {
        guard let first = weightData.first, let last = weightData.last, weightData.count > 1 else {
            return nil
        }
        return last.weightKg - first.weightKg
    }
}
