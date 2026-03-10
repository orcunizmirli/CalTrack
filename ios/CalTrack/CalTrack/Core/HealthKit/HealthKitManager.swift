import Foundation
import HealthKit

@MainActor
class HealthKitManager: ObservableObject {
    static let shared = HealthKitManager()

    private let healthStore = HKHealthStore()
    @Published var isAuthorized = false

    var isHealthDataAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    // MARK: - Authorization

    func requestAuthorization() async throws {
        guard isHealthDataAvailable else { return }

        let readTypes: Set<HKObjectType> = [
            HKQuantityType(.height),
            HKQuantityType(.bodyMass),
            HKQuantityType(.bodyFatPercentage),
            HKQuantityType(.dateOfBirth),
            HKQuantityType(.stepCount),
            HKQuantityType(.activeEnergyBurned),
            HKQuantityType(.basalEnergyBurned),
            HKQuantityType(.heartRate),
            HKObjectType.workoutType(),
            HKQuantityType(.dietaryEnergyConsumed),
            HKQuantityType(.dietaryProtein),
            HKQuantityType(.dietaryCarbohydrates),
            HKQuantityType(.dietaryFatTotal),
            HKQuantityType(.dietaryWater)
        ]

        let writeTypes: Set<HKSampleType> = [
            HKQuantityType(.dietaryEnergyConsumed),
            HKQuantityType(.dietaryProtein),
            HKQuantityType(.dietaryCarbohydrates),
            HKQuantityType(.dietaryFatTotal),
            HKQuantityType(.dietaryWater),
            HKQuantityType(.bodyMass)
        ]

        try await healthStore.requestAuthorization(toShare: writeTypes, read: readTypes)
        isAuthorized = true
    }

    // MARK: - Read Data

    func getLatestWeight() async -> Double? {
        return await getLatestQuantity(type: .bodyMass, unit: .gramUnit(with: .kilo))
    }

    func getLatestHeight() async -> Double? {
        return await getLatestQuantity(type: .height, unit: .meterUnit(with: .centi))
    }

    func getLatestBodyFat() async -> Double? {
        return await getLatestQuantity(type: .bodyFatPercentage, unit: .percent())
    }

    func getAge() -> Int? {
        do {
            let dateOfBirth = try healthStore.dateOfBirthComponents()
            guard let birthDate = dateOfBirth.date else { return nil }
            let age = Calendar.current.dateComponents([.year], from: birthDate, to: Date()).year
            return age
        } catch {
            return nil
        }
    }

    func getBiologicalSex() -> Gender? {
        do {
            let sex = try healthStore.biologicalSex()
            switch sex.biologicalSex {
            case .male: return .male
            case .female: return .female
            default: return nil
            }
        } catch {
            return nil
        }
    }

    func getTodaySteps() async -> Int {
        let steps = await getDailySumQuantity(type: .stepCount, unit: .count())
        return Int(steps)
    }

    func getTodayActiveCalories() async -> Double {
        return await getDailySumQuantity(type: .activeEnergyBurned, unit: .kilocalorie())
    }

    func getTodayBasalCalories() async -> Double {
        return await getDailySumQuantity(type: .basalEnergyBurned, unit: .kilocalorie())
    }

    func getRecentWorkouts(limit: Int = 10) async -> [HKWorkout] {
        return await withCheckedContinuation { continuation in
            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
            let query = HKSampleQuery(
                sampleType: .workoutType(),
                predicate: nil,
                limit: limit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, _ in
                let workouts = (samples as? [HKWorkout]) ?? []
                continuation.resume(returning: workouts)
            }
            healthStore.execute(query)
        }
    }

    // MARK: - Write Data

    func saveCalorieIntake(calories: Double, date: Date) async throws {
        let type = HKQuantityType(.dietaryEnergyConsumed)
        let quantity = HKQuantity(unit: .kilocalorie(), doubleValue: calories)
        let sample = HKQuantitySample(type: type, quantity: quantity, start: date, end: date)
        try await healthStore.save(sample)
    }

    func saveWaterIntake(milliliters: Double, date: Date) async throws {
        let type = HKQuantityType(.dietaryWater)
        let quantity = HKQuantity(unit: .literUnit(with: .milli), doubleValue: milliliters)
        let sample = HKQuantitySample(type: type, quantity: quantity, start: date, end: date)
        try await healthStore.save(sample)
    }

    func saveWeight(kg: Double, date: Date) async throws {
        let type = HKQuantityType(.bodyMass)
        let quantity = HKQuantity(unit: .gramUnit(with: .kilo), doubleValue: kg)
        let sample = HKQuantitySample(type: type, quantity: quantity, start: date, end: date)
        try await healthStore.save(sample)
    }

    // MARK: - Private Helpers

    private func getLatestQuantity(type: HKQuantityTypeIdentifier, unit: HKUnit) async -> Double? {
        return await withCheckedContinuation { continuation in
            let quantityType = HKQuantityType(type)
            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
            let query = HKSampleQuery(
                sampleType: quantityType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, _ in
                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil)
                    return
                }
                continuation.resume(returning: sample.quantity.doubleValue(for: unit))
            }
            healthStore.execute(query)
        }
    }

    private func getDailySumQuantity(type: HKQuantityTypeIdentifier, unit: HKUnit) async -> Double {
        return await withCheckedContinuation { continuation in
            let quantityType = HKQuantityType(type)
            let startOfDay = Calendar.current.startOfDay(for: Date())
            let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictStartDate)

            let query = HKStatisticsQuery(
                quantityType: quantityType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, _ in
                guard let sum = result?.sumQuantity() else {
                    continuation.resume(returning: 0)
                    return
                }
                continuation.resume(returning: sum.doubleValue(for: unit))
            }
            healthStore.execute(query)
        }
    }
}
