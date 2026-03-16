import Foundation
import WatchConnectivity
import HealthKit

struct WatchMealItem: Codable {
    let name: String
    let calories: Double
    let proteinG: Double
    let mealType: String
}

@MainActor
class WatchConnectivityManager: NSObject, ObservableObject {
    @Published var caloriesConsumed: Double = 0
    @Published var calorieGoal: Int = 2000
    @Published var proteinG: Double = 0
    @Published var carbsG: Double = 0
    @Published var fatG: Double = 0
    @Published var waterMl: Int = 0
    @Published var waterGoal: Int = 2500
    @Published var todayMeals: [WatchMealItem] = []

    var caloriesRemaining: Double {
        Double(calorieGoal) - caloriesConsumed
    }

    private let healthStore = HKHealthStore()

    override init() {
        super.init()

        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }

        // Read HealthKit data directly on Watch
        Task { await fetchHealthKitData() }
    }

    func addWater(ml: Int) {
        waterMl += ml

        // Send update to iPhone
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(
                ["action": "addWater", "amount": ml],
                replyHandler: nil
            )
        }
    }

    private func fetchHealthKitData() async {
        guard HKHealthStore.isHealthDataAvailable() else { return }

        let stepType = HKQuantityType(.stepCount)
        let calorieType = HKQuantityType(.activeEnergyBurned)

        let types: Set<HKSampleType> = [stepType, calorieType]

        do {
            try await healthStore.requestAuthorization(toShare: [], read: types)
        } catch {
            print("Watch HealthKit auth error: \(error)")
        }
    }
}

extension WatchConnectivityManager: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("Watch session activation error: \(error)")
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        Task { @MainActor in
            if let calories = applicationContext["caloriesConsumed"] as? Double {
                caloriesConsumed = calories
            }
            if let goal = applicationContext["calorieGoal"] as? Int {
                calorieGoal = goal
            }
            if let protein = applicationContext["proteinG"] as? Double {
                proteinG = protein
            }
            if let carbs = applicationContext["carbsG"] as? Double {
                carbsG = carbs
            }
            if let fat = applicationContext["fatG"] as? Double {
                fatG = fat
            }
            if let water = applicationContext["waterMl"] as? Int {
                waterMl = water
            }
            if let wGoal = applicationContext["waterGoal"] as? Int {
                waterGoal = wGoal
            }
            if let mealsData = applicationContext["meals"] as? Data,
               let meals = try? JSONDecoder().decode([WatchMealItem].self, from: mealsData) {
                todayMeals = meals
            }
        }
    }
}
