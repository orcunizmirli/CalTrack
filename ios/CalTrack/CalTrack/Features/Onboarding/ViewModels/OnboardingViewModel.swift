import Foundation
import SwiftUI

@MainActor
class OnboardingViewModel: ObservableObject {
    @Published var currentStep = 0
    @Published var name = ""
    @Published var gender: Gender = .male
    @Published var birthDate = Calendar.current.date(byAdding: .year, value: -25, to: Date())!
    @Published var heightCm: Double = 170
    @Published var weightKg: Double = 70
    @Published var bodyFatPct: Double? = nil
    @Published var bodyFatMethod: BodyFatMethod = .none
    @Published var activityLevel: ActivityLevel = .moderate
    @Published var goalType: GoalType = .loseWeight
    @Published var weeklyChangeKg: Double = 0.5
    @Published var targetWeight: Double = 65

    // Makro goals
    @Published var proteinG: Int = 150
    @Published var carbsG: Int = 200
    @Published var fatG: Int = 70

    // Calculated
    @Published var dailyCalories: Int = 2000
    @Published var bmr: Double = 0
    @Published var tdee: Double = 0
    @Published var estimatedBodyFat: Double? = nil

    // HealthKit
    @Published var useHealthKit = false

    // For US Navy method
    @Published var waistCm: Double = 85
    @Published var neckCm: Double = 38
    @Published var hipCm: Double = 95

    let healthKit = HealthKitManager.shared
    let totalSteps = 7

    enum BodyFatMethod: String, CaseIterable {
        case none = "Bilmiyorum"
        case manual = "Biliyorum"
        case usNavy = "Ölçüm ile Tahmin"
        case bmi = "BMI ile Tahmin"
    }

    var age: Int {
        Calendar.current.dateComponents([.year], from: birthDate, to: Date()).year ?? 25
    }

    func calculateAll() {
        // Body fat
        switch bodyFatMethod {
        case .manual:
            break // Already set
        case .usNavy:
            bodyFatPct = BodyFatEstimator.usNavyMethod(
                gender: gender, heightCm: heightCm,
                waistCm: waistCm, neckCm: neckCm,
                hipCm: gender == .female ? hipCm : nil
            )
        case .bmi:
            bodyFatPct = BodyFatEstimator.bmiBasedEstimate(
                gender: gender, weightKg: weightKg,
                heightCm: heightCm, age: age
            )
        case .none:
            bodyFatPct = nil
        }

        // BMR
        if let bf = bodyFatPct {
            bmr = CalorieCalculator.bmrKatchMcArdle(weightKg: weightKg, bodyFatPct: bf)
        } else {
            bmr = CalorieCalculator.bmrMifflinStJeor(
                weightKg: weightKg, heightCm: heightCm,
                age: age, gender: gender
            )
        }

        // TDEE
        tdee = CalorieCalculator.tdee(bmr: bmr, activityLevel: activityLevel)

        // Daily calories
        dailyCalories = CalorieCalculator.dailyCalorieTarget(
            tdee: tdee, goalType: goalType, weeklyChangeKg: weeklyChangeKg
        )

        // Suggested macros
        let suggested = CalorieCalculator.suggestedMacros(
            dailyCalories: dailyCalories,
            goalType: goalType,
            weightKg: weightKg
        )
        proteinG = suggested.protein
        carbsG = suggested.carbs
        fatG = suggested.fat
    }

    func updateCarbsFromMacros() {
        carbsG = CalorieCalculator.remainingCarbs(
            dailyCalories: dailyCalories,
            proteinGrams: proteinG,
            fatGrams: fatG
        )
    }

    var macroCalorieTotal: Int {
        CalorieCalculator.caloriesFromMacros(proteinG: proteinG, carbsG: carbsG, fatG: fatG)
    }

    var macroCalorieDifference: Int {
        dailyCalories - macroCalorieTotal
    }

    func importHealthData() async {
        guard useHealthKit else { return }
        try? await healthKit.requestAuthorization()

        if let weight = await healthKit.getLatestWeight() {
            weightKg = weight
        }
        if let height = await healthKit.getLatestHeight() {
            heightCm = height
        }
        if let bf = await healthKit.getLatestBodyFat() {
            bodyFatPct = bf * 100 // HealthKit returns as decimal
            bodyFatMethod = .manual
        }
        if let hkAge = healthKit.getAge() {
            let cal = Calendar.current
            birthDate = cal.date(byAdding: .year, value: -hkAge, to: Date()) ?? birthDate
        }
        if let hkGender = healthKit.getBiologicalSex() {
            gender = hkGender
        }
    }

    func saveProfile() {
        let defaults = UserDefaultsManager.shared
        defaults.dailyCalorieGoal = dailyCalories
        defaults.proteinGoal = proteinG
        defaults.carbsGoal = carbsG
        defaults.fatGoal = fatG
    }

    func nextStep() {
        if currentStep < totalSteps - 1 {
            withAnimation { currentStep += 1 }
        }
    }

    func previousStep() {
        if currentStep > 0 {
            withAnimation { currentStep -= 1 }
        }
    }
}
