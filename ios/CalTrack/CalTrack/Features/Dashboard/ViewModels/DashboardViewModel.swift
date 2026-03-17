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
    @Published var showGoalReached = false
    @Published var showWaterGoalReached = false
    private var previousCalorieProgress: Double = 0

    let healthKit = HealthKitManager.shared

    var calorieGoal: Int { UserDefaultsManager.shared.dailyCalorieGoal }
    var proteinGoal: Int { UserDefaultsManager.shared.proteinGoal }
    var carbsGoal: Int { UserDefaultsManager.shared.carbsGoal }
    var fatGoal: Int { UserDefaultsManager.shared.fatGoal }

    // Calculate totals from actual meal entries, not stored DailyLog values
    var totalCalories: Double {
        meals.values.flatMap { $0 }.reduce(0) { $0 + $1.calories }
    }
    var totalProtein: Double {
        meals.values.flatMap { $0 }.reduce(0) { $0 + $1.proteinG }
    }
    var totalCarbs: Double {
        meals.values.flatMap { $0 }.reduce(0) { $0 + $1.carbsG }
    }
    var totalFat: Double {
        meals.values.flatMap { $0 }.reduce(0) { $0 + $1.fatG }
    }

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

        // Check if calorie goal just reached (show once per day)
        let newProgress = calorieProgress
        if previousCalorieProgress < 1.0 && newProgress >= 1.0 && selectedDate.isToday {
            let lastShownKey = "goalReachedLastShownDate"
            let todayString = selectedDate.formatted(.iso8601.year().month().day())
            if UserDefaults.standard.string(forKey: lastShownKey) != todayString {
                showGoalReached = true
                UserDefaults.standard.set(todayString, forKey: lastShownKey)
                HapticManager.success()
            }
        }
        previousCalorieProgress = newProgress

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

    func copyMealToToday(_ meal: MealEntry, context: ModelContext) {
        let copy = meal.duplicate(toDate: Date())
        context.insert(copy)
        Task { await loadData(context: context) }
    }

    func copyMealsFromYesterday(mealType: MealType, context: ModelContext) async {
        guard let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) else { return }
        let startOfYesterday = yesterday.startOfDay
        let endOfYesterday = yesterday.endOfDay
        let mealTypeRaw = mealType.rawValue

        let descriptor = FetchDescriptor<MealEntry>(
            predicate: #Predicate<MealEntry> { entry in
                entry.date >= startOfYesterday && entry.date <= endOfYesterday && entry.mealType == mealTypeRaw
            }
        )

        guard let yesterdayMeals = try? context.fetch(descriptor), !yesterdayMeals.isEmpty else { return }

        for meal in yesterdayMeals {
            let copy = meal.duplicate(toDate: selectedDate, mealType: mealType)
            context.insert(copy)
        }

        await loadData(context: context)
    }
}
