import SwiftUI

struct MacroSetupView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Image(systemName: "chart.pie.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.accentColor)

                    Text("Makro Hedefleri")
                        .font(.ctTitle)

                    Text("Günlük makro besin hedeflerini ayarla")
                        .font(.ctSubheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)

                // Daily Calories Display
                VStack(spacing: 4) {
                    Text("Günlük Kalori Hedefi")
                        .font(.ctSubheadline)
                        .foregroundColor(.secondary)
                    Text("\(viewModel.dailyCalories)")
                        .font(.ctCalorieDisplay)
                        .foregroundColor(.ctCalories)
                    Text("kcal")
                        .font(.ctSubheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.ctSecondaryBg)
                .cornerRadius(14)

                // Macro Sliders
                VStack(spacing: 20) {
                    // Protein
                    MacroSliderRow(
                        name: "Protein",
                        value: $viewModel.proteinG,
                        range: 50...300,
                        color: .ctProtein,
                        caloriePerGram: 4,
                        onChange: { viewModel.updateCarbsFromMacros() }
                    )

                    // Fat
                    MacroSliderRow(
                        name: "Yağ",
                        value: $viewModel.fatG,
                        range: 20...200,
                        color: .ctFat,
                        caloriePerGram: 9,
                        onChange: { viewModel.updateCarbsFromMacros() }
                    )

                    // Carbs (calculated)
                    VStack(spacing: 8) {
                        HStack {
                            Circle()
                                .fill(Color.ctCarbs)
                                .frame(width: 12, height: 12)
                            Text("Karbonhidrat")
                                .font(.ctHeadline)
                            Spacer()
                            Text("\(viewModel.carbsG)g")
                                .font(.ctMacroValue)
                                .foregroundColor(.ctCarbs)
                            Text("(\(viewModel.carbsG * 4) kcal)")
                                .font(.ctCaption)
                                .foregroundColor(.secondary)
                        }

                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.ctCarbs)
                                .font(.caption)
                            Text("Karbonhidrat, protein ve yağdan kalan kaloriye göre otomatik hesaplanır")
                                .font(.ctCaption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color.ctSecondaryBg)
                .cornerRadius(14)

                // Macro Pie Chart
                VStack(spacing: 12) {
                    Text("Makro Dağılımı")
                        .font(.ctHeadline)

                    MacroPieChart(
                        proteinG: viewModel.proteinG,
                        carbsG: viewModel.carbsG,
                        fatG: viewModel.fatG
                    )
                    .frame(height: 160)

                    // Calorie difference indicator
                    let diff = viewModel.macroCalorieDifference
                    if abs(diff) > 10 {
                        HStack {
                            Image(systemName: diff > 0 ? "exclamationmark.triangle.fill" : "exclamationmark.triangle.fill")
                                .foregroundColor(.ctWarning)
                            Text(diff > 0 ?
                                 "\(diff) kcal makrolara dağıtılmamış" :
                                 "\(abs(diff)) kcal fazla dağıtılmış")
                                .font(.ctCaption)
                                .foregroundColor(.ctWarning)
                        }
                    } else {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.ctSuccess)
                            Text("Makrolar kalori hedefine uygun")
                                .font(.ctCaption)
                                .foregroundColor(.ctSuccess)
                        }
                    }
                }
                .padding()
                .background(Color.ctSecondaryBg)
                .cornerRadius(14)
            }
            .padding(.horizontal)
            .padding(.bottom, 100)
        }
    }
}

struct MacroSliderRow: View {
    let name: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    let color: Color
    let caloriePerGram: Int
    var onChange: (() -> Void)?

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Circle()
                    .fill(color)
                    .frame(width: 12, height: 12)
                Text(name)
                    .font(.ctHeadline)
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
                    set: {
                        value = Int($0)
                        onChange?()
                    }
                ),
                in: Double(range.lowerBound)...Double(range.upperBound),
                step: 5
            )
            .tint(color)
        }
    }
}

struct MacroPieChart: View {
    let proteinG: Int
    let carbsG: Int
    let fatG: Int

    var body: some View {
        let total = Double(proteinG * 4 + carbsG * 4 + fatG * 9)
        let proteinPct = total > 0 ? Double(proteinG * 4) / total : 0.33
        let carbsPct = total > 0 ? Double(carbsG * 4) / total : 0.33
        let fatPct = total > 0 ? Double(fatG * 9) / total : 0.34

        HStack(spacing: 24) {
            ZStack {
                Circle()
                    .trim(from: 0, to: proteinPct)
                    .stroke(Color.ctProtein, lineWidth: 20)
                    .rotationEffect(.degrees(-90))

                Circle()
                    .trim(from: proteinPct, to: proteinPct + carbsPct)
                    .stroke(Color.ctCarbs, lineWidth: 20)
                    .rotationEffect(.degrees(-90))

                Circle()
                    .trim(from: proteinPct + carbsPct, to: 1)
                    .stroke(Color.ctFat, lineWidth: 20)
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 2) {
                    Text("\(Int(total))")
                        .font(.ctTitle2)
                        .fontWeight(.bold)
                    Text("kcal")
                        .font(.ctCaption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 120, height: 120)

            VStack(alignment: .leading, spacing: 12) {
                MacroLegendRow(color: .ctProtein, name: "Protein", grams: proteinG, percentage: proteinPct)
                MacroLegendRow(color: .ctCarbs, name: "Karb", grams: carbsG, percentage: carbsPct)
                MacroLegendRow(color: .ctFat, name: "Yağ", grams: fatG, percentage: fatPct)
            }
        }
    }
}

struct MacroLegendRow: View {
    let color: Color
    let name: String
    let grams: Int
    let percentage: Double

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
            VStack(alignment: .leading) {
                Text(name)
                    .font(.ctCaption)
                    .foregroundColor(.secondary)
                Text("\(grams)g (\(Int(percentage * 100))%)")
                    .font(.ctSubheadline)
                    .fontWeight(.medium)
            }
        }
    }
}
