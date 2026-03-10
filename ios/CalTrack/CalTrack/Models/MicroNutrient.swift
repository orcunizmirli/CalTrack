import Foundation

struct MicroNutrient: Identifiable, Codable {
    let id: String
    let name: String
    let unit: String
    var currentAmount: Double
    let rdaAmount: Double  // Recommended Daily Allowance

    var progress: Double {
        guard rdaAmount > 0 else { return 0 }
        return min(currentAmount / rdaAmount, 2.0)
    }

    var progressPercentage: Int {
        Int(progress * 100)
    }

    var status: NutrientStatus {
        switch progress {
        case ..<0.5: return .deficient
        case 0.5..<0.8: return .low
        case 0.8..<1.2: return .optimal
        case 1.2..<2.0: return .high
        default: return .excessive
        }
    }
}

enum NutrientStatus: String {
    case deficient = "Eksik"
    case low = "Düşük"
    case optimal = "Optimal"
    case high = "Yüksek"
    case excessive = "Fazla"

    var color: String {
        switch self {
        case .deficient: return "ctError"
        case .low: return "ctWarning"
        case .optimal: return "ctSuccess"
        case .high: return "ctWarning"
        case .excessive: return "ctError"
        }
    }
}

struct MicroNutrientDefaults {
    /// Returns default RDA values based on gender and age
    static func defaultRDA(gender: Gender, age: Int) -> [MicroNutrient] {
        let isMale = gender == .male
        return [
            // Vitamins
            MicroNutrient(id: "vit_a", name: "A Vitamini", unit: "mcg", currentAmount: 0,
                         rdaAmount: isMale ? 900 : 700),
            MicroNutrient(id: "vit_c", name: "C Vitamini", unit: "mg", currentAmount: 0,
                         rdaAmount: isMale ? 90 : 75),
            MicroNutrient(id: "vit_d", name: "D Vitamini", unit: "mcg", currentAmount: 0,
                         rdaAmount: 15),
            MicroNutrient(id: "vit_e", name: "E Vitamini", unit: "mg", currentAmount: 0,
                         rdaAmount: 15),
            MicroNutrient(id: "vit_k", name: "K Vitamini", unit: "mcg", currentAmount: 0,
                         rdaAmount: isMale ? 120 : 90),
            MicroNutrient(id: "vit_b1", name: "B1 (Tiamin)", unit: "mg", currentAmount: 0,
                         rdaAmount: isMale ? 1.2 : 1.1),
            MicroNutrient(id: "vit_b2", name: "B2 (Riboflavin)", unit: "mg", currentAmount: 0,
                         rdaAmount: isMale ? 1.3 : 1.1),
            MicroNutrient(id: "vit_b3", name: "B3 (Niasin)", unit: "mg", currentAmount: 0,
                         rdaAmount: isMale ? 16 : 14),
            MicroNutrient(id: "vit_b6", name: "B6 Vitamini", unit: "mg", currentAmount: 0,
                         rdaAmount: isMale ? 1.3 : 1.3),
            MicroNutrient(id: "vit_b9", name: "B9 (Folat)", unit: "mcg", currentAmount: 0,
                         rdaAmount: 400),
            MicroNutrient(id: "vit_b12", name: "B12 Vitamini", unit: "mcg", currentAmount: 0,
                         rdaAmount: 2.4),

            // Minerals
            MicroNutrient(id: "calcium", name: "Kalsiyum", unit: "mg", currentAmount: 0,
                         rdaAmount: 1000),
            MicroNutrient(id: "iron", name: "Demir", unit: "mg", currentAmount: 0,
                         rdaAmount: isMale ? 8 : 18),
            MicroNutrient(id: "magnesium", name: "Magnezyum", unit: "mg", currentAmount: 0,
                         rdaAmount: isMale ? 420 : 320),
            MicroNutrient(id: "potassium", name: "Potasyum", unit: "mg", currentAmount: 0,
                         rdaAmount: isMale ? 3400 : 2600),
            MicroNutrient(id: "zinc", name: "Çinko", unit: "mg", currentAmount: 0,
                         rdaAmount: isMale ? 11 : 8),
            MicroNutrient(id: "phosphorus", name: "Fosfor", unit: "mg", currentAmount: 0,
                         rdaAmount: 700),
            MicroNutrient(id: "sodium", name: "Sodyum", unit: "mg", currentAmount: 0,
                         rdaAmount: 2300) // Upper limit
        ]
    }
}
