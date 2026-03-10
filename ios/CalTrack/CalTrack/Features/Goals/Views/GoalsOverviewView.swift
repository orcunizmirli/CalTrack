import SwiftUI

struct GoalsOverviewView: View {
    @State private var dailyCalories = UserDefaultsManager.shared.dailyCalorieGoal
    @State private var proteinG = UserDefaultsManager.shared.proteinGoal
    @State private var carbsG = UserDefaultsManager.shared.carbsGoal
    @State private var fatG = UserDefaultsManager.shared.fatGoal
    @State private var showMicroNutrients = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Calorie Goal
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.ctCalories)
                        Text("Günlük Kalori Hedefi")
                            .font(.ctHeadline)
                        Spacer()
                    }

                    HStack {
                        Text("\(dailyCalories)")
                            .font(.ctCalorieDisplay)
                            .foregroundColor(.ctCalories)
                        Text("kcal")
                            .font(.ctSubheadline)
                            .foregroundColor(.secondary)
                    }

                    Stepper("", value: $dailyCalories, in: 800...5000, step: 50)
                        .labelsHidden()
                        .onChange(of: dailyCalories) { _, newValue in
                            UserDefaultsManager.shared.dailyCalorieGoal = newValue
                        }
                }
                .padding()
                .background(Color.ctSecondaryBg)
                .cornerRadius(14)

                // Macro Goals
                VStack(spacing: 16) {
                    HStack {
                        Image(systemName: "chart.pie.fill")
                            .foregroundColor(.accentColor)
                        Text("Makro Hedefleri")
                            .font(.ctHeadline)
                        Spacer()
                    }

                    MacroGoalRow(
                        name: "Protein", value: $proteinG,
                        range: 20...400, color: .ctProtein, caloriePerGram: 4,
                        onChange: { UserDefaultsManager.shared.proteinGoal = proteinG; recalcCarbs() }
                    )

                    MacroGoalRow(
                        name: "Yağ", value: $fatG,
                        range: 10...250, color: .ctFat, caloriePerGram: 9,
                        onChange: { UserDefaultsManager.shared.fatGoal = fatG; recalcCarbs() }
                    )

                    // Carbs (calculated)
                    VStack(spacing: 8) {
                        HStack {
                            Circle().fill(Color.ctCarbs).frame(width: 10, height: 10)
                            Text("Karbonhidrat")
                                .font(.ctBody)
                            Spacer()
                            Text("\(carbsG)g")
                                .font(.ctMacroValue)
                                .foregroundColor(.ctCarbs)
                            Text("(\(carbsG * 4) kcal)")
                                .font(.ctCaption)
                                .foregroundColor(.secondary)
                        }

                        HStack {
                            Image(systemName: "arrow.right.circle.fill")
                                .foregroundColor(.ctCarbs)
                                .font(.caption)
                            Text("Kalan kaloriden otomatik hesaplanır")
                                .font(.ctCaption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Divider()

                    // Total check
                    let totalCal = proteinG * 4 + carbsG * 4 + fatG * 9
                    HStack {
                        Text("Toplam Makro Kalorisi")
                            .font(.ctSubheadline)
                        Spacer()
                        Text("\(totalCal) / \(dailyCalories) kcal")
                            .font(.ctSubheadline)
                            .foregroundColor(abs(totalCal - dailyCalories) < 50 ? .ctSuccess : .ctWarning)
                    }

                    // Pie chart
                    MacroPieChart(proteinG: proteinG, carbsG: carbsG, fatG: fatG)
                        .frame(height: 140)
                }
                .padding()
                .background(Color.ctSecondaryBg)
                .cornerRadius(14)

                // Micro nutrients link
                Button(action: { showMicroNutrients = true }) {
                    HStack {
                        Image(systemName: "leaf.fill")
                            .foregroundColor(.green)
                        Text("Mikro Besin Takibi")
                            .font(.ctHeadline)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.ctSecondaryBg)
                    .cornerRadius(14)
                }
                .foregroundColor(.primary)
            }
            .padding()
        }
        .navigationTitle("Hedefler")
        .sheet(isPresented: $showMicroNutrients) {
            MicroNutrientView()
        }
    }

    private func recalcCarbs() {
        carbsG = CalorieCalculator.remainingCarbs(
            dailyCalories: dailyCalories,
            proteinGrams: proteinG,
            fatGrams: fatG
        )
        UserDefaultsManager.shared.carbsGoal = carbsG
    }
}

struct MacroGoalRow: View {
    let name: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    let color: Color
    let caloriePerGram: Int
    var onChange: (() -> Void)?

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Circle().fill(color).frame(width: 10, height: 10)
                Text(name)
                    .font(.ctBody)
                Spacer()
                Text("\(value)g")
                    .font(.ctMacroValue)
                    .foregroundColor(color)
                Text("(\(value * caloriePerGram) kcal)")
                    .font(.ctCaption)
                    .foregroundColor(.secondary)
            }

            Slider(
                value: Binding(
                    get: { Double(value) },
                    set: { value = Int($0); onChange?() }
                ),
                in: Double(range.lowerBound)...Double(range.upperBound),
                step: 5
            )
            .tint(color)
        }
    }
}
