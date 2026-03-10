import Foundation
import SwiftUI
import SwiftData

@MainActor
class DashboardViewModel: ObservableObject {
    @Published var selectedDate: Date = .today
    @Published var dailyLog: DailyLog?
    @Published var meals: [MealType: [MealEntry]] = [:]
    @Published var isLoading = false
    @Published var todaySteps = 0
    @Published var activeCalories: Double = 0

    let healthKit = HealthKitManager.shared

    var calorieGoal: Int { UserDefaultsManager.shared.dailyCalorieGoal }
    var proteinGoal: Int { UserDefaultsManager.shared.proteinGoal }
    var carbsGoal: Int { UserDefaultsManager.shared.carbsGoal }
    var fatGoal: Int { UserDefaultsManager.shared.fatGoal }

    var totalCalories: Double { dailyLog?.totalCalories ?? 0 }
    var totalProtein: Double { dailyLog?.totalProteinG ?? 0 }
    var totalCarbs: Double { dailyLog?.totalCarbsG ?? 0 }
    var totalFat: Double { dailyLog?.totalFatG ?? 0 }

    var caloriesRemaining: Double {
        Double(calorieGoal) - totalCalories + activeCalories
    }

    var calorieProgress: Double {
        guard calorieGoal > 0 else { return 0 }
        return min(totalCalories / Double(calorieGoal), 1.0)
    }

    func loadData(context: ModelContext) async {
        isLoading = true

        // Fetch daily log
        let startOfDay = selectedDate.startOfDay
        let endOfDay = selectedDate.endOfDay
        let logDescriptor = FetchDescriptor<DailyLog>(
            predicate: #Predicate<DailyLog> { log in
                log.date >= startOfDay && log.date <= endOfDay
            }
        )

        if let logs = try? context.fetch(logDescriptor), let log = logs.first {
            dailyLog = log
        } else {
            let newLog = DailyLog(date: selectedDate)
            context.insert(newLog)
            dailyLog = newLog
        }

        // Fetch meals
        let mealDescriptor = FetchDescriptor<MealEntry>(
            predicate: #Predicate<MealEntry> { entry in
                entry.date >= startOfDay && entry.date <= endOfDay
            },
            sortBy: [SortDescriptor(\.createdAt)]
        )

        if let mealEntries = try? context.fetch(mealDescriptor) {
            var grouped: [MealType: [MealEntry]] = [:]
            for entry in mealEntries {
                let type = MealType(rawValue: entry.mealType) ?? .snack
                grouped[type, default: []].append(entry)
            }
            meals = grouped
        }

        // HealthKit data
        if selectedDate.isToday {
            todaySteps = await healthKit.getTodaySteps()
            activeCalories = await healthKit.getTodayActiveCalories()
        }

        isLoading = false
    }

    func caloriesForMealType(_ type: MealType) -> Double {
        meals[type]?.reduce(0) { $0 + $1.calories } ?? 0
    }

    func mealsForType(_ type: MealType) -> [MealEntry] {
        meals[type] ?? []
    }

    func deleteMeal(_ meal: MealEntry, context: ModelContext) {
        context.delete(meal)
        Task { await loadData(context: context) }
    }
}
