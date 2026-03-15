import SwiftUI

struct GoalsOverviewView: View {
    @State private var dailyCalories = UserDefaultsManager.shared.dailyCalorieGoal
    @State private var proteinG = UserDefaultsManager.shared.proteinGoal
    @State private var carbsG = UserDefaultsManager.shared.carbsGoal
    @State private var fatG = UserDefaultsManager.shared.fatGoal
    @State private var showMicroNutrients = false

    var body: some View {
        ScrollView {
            GlassEffectContainer {
                VStack(spacing: 16) {
                    // Calorie Goal
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "flame.fill")
                                .foregroundStyle(.ctAccent)
                            Text("Günlük Kalori Hedefi")
                                .font(.ctHeadline)
                            Spacer()
                        }

                        HStack {
                            Text("\(dailyCalories)")
                                .font(.ctCalorieDisplay)
                                .foregroundStyle(.ctAccent)
                            Text("kcal")
                                .font(.ctSubheadline)
                                .foregroundStyle(.ctTextSecondary)
                        }

                        Stepper("", value: $dailyCalories, in: 800...5000, step: 50)
                            .labelsHidden()
                            .onChange(of: dailyCalories) { _, newValue in
                                UserDefaultsManager.shared.dailyCalorieGoal = newValue
                            }
                    }
                    .glassCard()

                    // Macro Goals
                    VStack(spacing: 16) {
                        HStack {
                            Image(systemName: "chart.pie.fill")
                                .foregroundStyle(.ctAccent)
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
                                    .foregroundStyle(.ctCarbs)
                                Text("(\(carbsG * 4) kcal)")
                                    .font(.ctCaption)
                                    .foregroundStyle(.ctTextSecondary)
                            }

                            HStack {
                                Image(systemName: "arrow.right.circle.fill")
                                    .foregroundStyle(.ctCarbs)
                                    .font(.caption)
                                Text("Kalan kaloriden otomatik hesaplanır")
                                    .font(.ctCaption)
                                    .foregroundStyle(.ctTextSecondary)
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
                                .foregroundStyle(abs(totalCal - dailyCalories) < 50 ? .ctSuccess : .ctWarning)
                        }

                        // Pie chart
                        MacroPieChart(proteinG: proteinG, carbsG: carbsG, fatG: fatG)
                            .frame(height: 140)
                    }
                    .glassCard()

                    // Micro nutrients link
                    Button(action: { showMicroNutrients = true }) {
                        HStack {
                            Image(systemName: "leaf.fill")
                                .foregroundStyle(.green)
                            Text("Mikro Besin Takibi")
                                .font(.ctHeadline)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.ctTextSecondary)
                        }
                        .glassCard()
                    }
                    .foregroundStyle(.ctTextPrimary)
                }
                .padding()
            }
        }
        .background(Color.ctBackground)
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
                    .foregroundStyle(color)
                Text("(\(value * caloriePerGram) kcal)")
                    .font(.ctCaption)
                    .foregroundStyle(.ctTextSecondary)
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
