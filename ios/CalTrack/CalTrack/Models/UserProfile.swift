import Foundation
import SwiftData

@Model
final class UserProfile {
    var id: String
    var email: String?
    var name: String
    var gender: String       // "male" / "female"
    var birthDate: Date?
    var heightCm: Double
    var weightKg: Double
    var bodyFatPct: Double?  // nullable
    var activityLevel: String // sedentary, light, moderate, active, very_active
    var unitSystem: String   // metric / imperial
    var language: String     // tr / en
    var createdAt: Date
    var updatedAt: Date

    init(
        id: String = UUID().uuidString,
        email: String? = nil,
        name: String = "",
        gender: String = "male",
        birthDate: Date? = nil,
        heightCm: Double = 170,
        weightKg: Double = 70,
        bodyFatPct: Double? = nil,
        activityLevel: String = "moderate",
        unitSystem: String = "metric",
        language: String = "tr"
    ) {
        self.id = id
        self.email = email
        self.name = name
        self.gender = gender
        self.birthDate = birthDate
        self.heightCm = heightCm
        self.weightKg = weightKg
        self.bodyFatPct = bodyFatPct
        self.activityLevel = activityLevel
        self.unitSystem = unitSystem
        self.language = language
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    var genderEnum: Gender {
        Gender(rawValue: gender) ?? .male
    }

    var activityLevelEnum: ActivityLevel {
        ActivityLevel(rawValue: activityLevel) ?? .moderate
    }

    var age: Int {
        guard let birthDate = birthDate else { return 25 }
        return Calendar.current.dateComponents([.year], from: birthDate, to: Date()).year ?? 25
    }
}
