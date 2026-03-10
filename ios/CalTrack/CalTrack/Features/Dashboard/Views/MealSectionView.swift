import SwiftUI

struct MealSectionView: View {
    let mealType: MealType
    let meals: [MealEntry]
    let totalCalories: Double
    let onAdd: () -> Void
    let onDelete: (MealEntry) -> Void

    var body: some View {
        VStack(spacing: 8) {
            // Header
            HStack {
                Image(systemName: mealType.icon)
                    .foregroundColor(mealTypeColor)
                    .font(.title3)

                Text(mealType.displayName)
                    .font(.ctHeadline)

                Spacer()

                if totalCalories > 0 {
                    Text("\(Int(totalCalories)) kcal")
                        .font(.ctSubheadline)
                        .foregroundColor(.secondary)
                }

                Button(action: onAdd) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.accentColor)
                }
            }

            // Meal Items
            if meals.isEmpty {
                Button(action: onAdd) {
                    HStack {
                        Image(systemName: "plus")
                            .foregroundColor(.accentColor)
                        Text("Yemek Ekle")
                            .font(.ctSubheadline)
                            .foregroundColor(.accentColor)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.accentColor.opacity(0.08))
                    .cornerRadius(10)
                }
            } else {
                ForEach(meals, id: \.id) { meal in
                    MealItemRow(meal: meal, onDelete: { onDelete(meal) })
                }
            }
        }
        .padding()
        .background(Color.ctSecondaryBg)
        .cornerRadius(14)
    }

    private var mealTypeColor: Color {
        switch mealType {
        case .breakfast: return .ctBreakfast
        case .lunch: return .ctLunch
        case .dinner: return .ctDinner
        case .snack: return .ctSnack
        }
    }
}

struct MealItemRow: View {
    let meal: MealEntry
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            if meal.isAIScan {
                Image(systemName: "camera.fill")
                    .foregroundColor(.accentColor)
                    .font(.caption)
                    .frame(width: 28, height: 28)
                    .background(Color.accentColor.opacity(0.1))
                    .cornerRadius(6)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(meal.foodName)
                    .font(.ctSubheadline)
                    .lineLimit(1)

                Text("\(Int(meal.quantityG))g")
                    .font(.ctCaption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Int(meal.calories)) kcal")
                    .font(.ctSubheadline)
                    .fontWeight(.medium)

                HStack(spacing: 4) {
                    Text("P:\(Int(meal.proteinG))")
                        .foregroundColor(.ctProtein)
                    Text("K:\(Int(meal.carbsG))")
                        .foregroundColor(.ctCarbs)
                    Text("Y:\(Int(meal.fatG))")
                        .foregroundColor(.ctFat)
                }
                .font(.system(size: 10))
            }
        }
        .padding(.vertical, 6)
        .swipeActions(edge: .trailing) {
            Button(role: .destructive, action: onDelete) {
                Label("Sil", systemImage: "trash")
            }
        }
    }
}
