import Foundation

struct BodyFatEstimator {

    /// US Navy Method for body fat estimation
    /// Requires waist, neck measurements (and hip for females)
    static func usNavyMethod(
        gender: Gender,
        heightCm: Double,
        waistCm: Double,
        neckCm: Double,
        hipCm: Double? = nil
    ) -> Double? {
        switch gender {
        case .male:
            guard waistCm > neckCm else { return nil }
            let bodyFat = 86.010 * log10(waistCm - neckCm) - 70.041 * log10(heightCm) + 36.76
            return max(2, min(60, bodyFat))

        case .female:
            guard let hipCm = hipCm else { return nil }
            guard (waistCm + hipCm) > neckCm else { return nil }
            let bodyFat = 163.205 * log10(waistCm + hipCm - neckCm) - 97.684 * log10(heightCm) - 78.387
            return max(8, min(60, bodyFat))
        }
    }

    /// BMI-based body fat estimation (less accurate but requires fewer inputs)
    static func bmiBasedEstimate(
        gender: Gender,
        weightKg: Double,
        heightCm: Double,
        age: Int
    ) -> Double {
        let heightM = heightCm / 100.0
        let bmi = weightKg / (heightM * heightM)

        switch gender {
        case .male:
            return max(2, 1.20 * bmi + 0.23 * Double(age) - 16.2)
        case .female:
            return max(8, 1.20 * bmi + 0.23 * Double(age) - 5.4)
        }
    }

    /// Calculate BMI
    static func bmi(weightKg: Double, heightCm: Double) -> Double {
        let heightM = heightCm / 100.0
        return weightKg / (heightM * heightM)
    }

    /// BMI Category
    static func bmiCategory(_ bmi: Double) -> String {
        switch bmi {
        case ..<18.5: return "Zayıf"
        case 18.5..<25.0: return "Normal"
        case 25.0..<30.0: return "Fazla Kilolu"
        case 30.0..<35.0: return "Obez (Sınıf 1)"
        case 35.0..<40.0: return "Obez (Sınıf 2)"
        default: return "Obez (Sınıf 3)"
        }
    }

    /// Body fat category
    static func bodyFatCategory(gender: Gender, bodyFatPct: Double) -> String {
        switch gender {
        case .male:
            switch bodyFatPct {
            case ..<6: return "Temel Yağ"
            case 6..<14: return "Atletik"
            case 14..<18: return "Fit"
            case 18..<25: return "Normal"
            default: return "Yüksek"
            }
        case .female:
            switch bodyFatPct {
            case ..<14: return "Temel Yağ"
            case 14..<21: return "Atletik"
            case 21..<25: return "Fit"
            case 25..<32: return "Normal"
            default: return "Yüksek"
            }
        }
    }
}
