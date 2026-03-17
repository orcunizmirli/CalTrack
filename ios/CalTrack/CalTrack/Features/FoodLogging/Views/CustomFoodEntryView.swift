import SwiftUI

struct CustomFoodEntryView: View {
    @State var mealType: MealType
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var foodName = ""
    @State private var proteinG: String = ""
    @State private var carbsG: String = ""
    @State private var fatG: String = ""
    @State private var quantityG: String = "100"

    // Auto-calculated: protein 4 kcal/g, carbs 4 kcal/g, fat 9 kcal/g
    private var caloriesPer100g: Double {
        let p = Double(proteinG) ?? 0
        let c = Double(carbsG) ?? 0
        let f = Double(fatG) ?? 0
        return p * 4 + c * 4 + f * 9
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Food name
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Yemek Adı")
                            .font(.ctSubheadline)
                            .foregroundStyle(.ctTextSecondary)
                        TextField("Örn: Ev yapımı köfte", text: $foodName)
                            .textFieldStyle(.plain)
                            .padding(12)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .glassEffect(.regular)
                    }

                    // Meal type
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Öğün")
                            .font(.ctSubheadline)
                            .foregroundStyle(.ctTextSecondary)
                        HStack(spacing: 8) {
                            ForEach(MealType.allCases, id: \.self) { type in
                                Button(action: { mealType = type }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: type.icon)
                                            .font(.caption2)
                                        Text(type.displayName)
                                            .font(.ctCaption)
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 8)
                                    .frame(maxWidth: .infinity)
                                    .background(mealType == type ? Color.ctAccent : Color.ctSurfaceElevated)
                                    .foregroundStyle(mealType == type ? .black : .ctTextPrimary)
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                }
                            }
                        }
                    }

                    // Quantity
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Miktar (gram)")
                            .font(.ctSubheadline)
                            .foregroundStyle(.ctTextSecondary)
                        TextField("100", text: $quantityG)
                            .keyboardType(.numberPad)
                            .textFieldStyle(.plain)
                            .padding(12)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .glassEffect(.regular)
                    }

                    // Nutrition
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Besin Değerleri (100g başına)")
                            .font(.ctSubheadline)
                            .foregroundStyle(.ctTextSecondary)

                        NutritionTextField(label: "Protein (g)", text: $proteinG, color: .ctProtein)
                        NutritionTextField(label: "Karbonhidrat (g)", text: $carbsG, color: .ctCarbs)
                        NutritionTextField(label: "Yağ (g)", text: $fatG, color: .ctFat)

                        // Auto-calculated calories
                        HStack(spacing: 12) {
                            Circle()
                                .fill(Color.ctCalories)
                                .frame(width: 8, height: 8)
                            Text("Kalori")
                                .font(.ctBody)
                            Spacer()
                            Text("\(Int(caloriesPer100g)) kcal")
                                .font(.ctHeadline)
                                .foregroundStyle(.ctCalories)
                        }
                        .padding(12)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .glassEffect(.regular)
                    }

                    // Add button
                    Button(action: addCustomFood) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("\(mealType.displayName)'ne Ekle")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(isValid ? Color.ctAccent : Color.ctAccent.opacity(0.3))
                        .foregroundStyle(.black)
                        .cornerRadius(14)
                        .fontWeight(.semibold)
                    }
                    .disabled(!isValid)
                }
                .padding()
            }
            .background(Color.ctBackground)
            .navigationTitle("Özel Yemek Ekle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") { dismiss() }
                }
            }
        }
    }

    private var isValid: Bool {
        !foodName.isEmpty && caloriesPer100g > 0
    }

    private func addCustomFood() {
        let qty = Double(quantityG) ?? 100
        let prot = Double(proteinG) ?? 0
        let carb = Double(carbsG) ?? 0
        let fat = Double(fatG) ?? 0

        let scale = qty / 100.0

        // Save custom food to local database for reuse (per 100g values)
        let foodItem = FoodItem(
            name: foodName,
            servingSizeG: 100,
            calories: caloriesPer100g,
            proteinG: prot,
            carbsG: carb,
            fatG: fat,
            source: "custom"
        )
        foodItem.lastUsedAt = Date()
        foodItem.useCount = 1
        modelContext.insert(foodItem)

        // Create the meal entry with actual quantity
        let entry = MealEntry(
            foodId: foodItem.id,
            foodName: foodName,
            mealType: mealType,
            quantityG: qty,
            calories: caloriesPer100g * scale,
            proteinG: prot * scale,
            carbsG: carb * scale,
            fatG: fat * scale
        )
        modelContext.insert(entry)
        dismiss()
    }
}

private struct NutritionTextField: View {
    let label: String
    @Binding var text: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.ctBody)
                .frame(width: 140, alignment: .leading)
            TextField("0", text: $text)
                .keyboardType(.decimalPad)
                .textFieldStyle(.plain)
                .multilineTextAlignment(.trailing)
        }
        .padding(12)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .glassEffect(.regular)
    }
}
