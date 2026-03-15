import SwiftUI

struct MacroSetupView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Image(systemName: "chart.pie.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.ctAccent)

                    Text("Makro Hedefleri")
                        .font(.ctTitle)

                    Text("Günlük makro besin hedeflerini ayarla")
                        .font(.ctSubheadline)
                        .foregroundStyle(.ctTextSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)

                // Daily Calories Display
                HStack {
                    Text("Günlük Kalori")
                        .font(.ctHeadline)
                    Spacer()
                    Text("\(viewModel.dailyCalories)")
                        .font(.ctTitle)
                        .foregroundStyle(.ctCalories)
                    Text("kcal")
                        .font(.ctSubheadline)
                        .foregroundStyle(.ctTextSecondary)
                }
                .glassCard(padding: 14, cornerRadius: 14)

                // Macro Sliders
                VStack(spacing: 16) {
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
                    VStack(spacing: 4) {
                        HStack {
                            Circle()
                                .fill(Color.ctCarbs)
                                .frame(width: 10, height: 10)
                            Text("Karb")
                                .font(.ctSubheadline)
                            Spacer()
                            Text("\(viewModel.carbsG)g")
                                .font(.ctMacroValue)
                                .foregroundStyle(.ctCarbs)
                            Text("\(viewModel.carbsG * 4) kcal")
                                .font(.ctCaption)
                                .foregroundStyle(.ctTextSecondary)
                        }

                        Text("Protein ve yağdan kalan kaloriye göre otomatik hesaplanır")
                            .font(.system(size: 10))
                            .foregroundStyle(.ctTextTertiary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .glassCard(padding: 14, cornerRadius: 14)

                // Macro Pie Chart
                VStack(spacing: 12) {
                    Text("Makro Dağılımı")
                        .font(.ctHeadline)

                    MacroPieChart(
                        proteinG: viewModel.proteinG,
                        carbsG: viewModel.carbsG,
                        fatG: viewModel.fatG
                    )

                    // Calorie difference indicator
                    let diff = viewModel.macroCalorieDifference
                    if abs(diff) > 10 {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.caption2)
                                .foregroundStyle(.ctWarning)
                            Text(diff > 0 ?
                                 "\(diff) kcal dağıtılmamış" :
                                 "\(abs(diff)) kcal fazla")
                                .font(.ctCaption)
                                .foregroundStyle(.ctWarning)
                        }
                    } else {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption2)
                                .foregroundStyle(.ctSuccess)
                            Text("Makrolar uygun")
                                .font(.ctCaption)
                                .foregroundStyle(.ctSuccess)
                        }
                    }
                }
                .glassCard(cornerRadius: 14)
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
        VStack(spacing: 4) {
            HStack {
                Circle()
                    .fill(color)
                    .frame(width: 10, height: 10)
                Text(name)
                    .font(.ctSubheadline)
                Spacer()
                Text("\(value)g")
                    .font(.ctMacroValue)
                    .foregroundStyle(color)
                Text("\(value * caloriePerGram) kcal")
                    .font(.ctCaption)
                    .foregroundStyle(.ctTextSecondary)
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
                    .stroke(Color.ctProtein, lineWidth: 18)
                    .rotationEffect(.degrees(-90))

                Circle()
                    .trim(from: proteinPct, to: proteinPct + carbsPct)
                    .stroke(Color.ctCarbs, lineWidth: 18)
                    .rotationEffect(.degrees(-90))

                Circle()
                    .trim(from: proteinPct + carbsPct, to: 1)
                    .stroke(Color.ctFat, lineWidth: 18)
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 2) {
                    Text("\(Int(total))")
                        .font(.ctTitle2)
                        .fontWeight(.bold)
                    Text("kcal")
                        .font(.ctCaption)
                        .foregroundStyle(.ctTextSecondary)
                }
            }
            .frame(width: 130, height: 130)

            VStack(alignment: .leading, spacing: 14) {
                MacroLegendRow(color: .ctProtein, name: "Protein", grams: proteinG, percentage: proteinPct)
                MacroLegendRow(color: .ctCarbs, name: "Karb", grams: carbsG, percentage: carbsPct)
                MacroLegendRow(color: .ctFat, name: "Yağ", grams: fatG, percentage: fatPct)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
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
                    .foregroundStyle(.ctTextSecondary)
                Text("\(grams)g (\(Int(percentage * 100))%)")
                    .font(.ctSubheadline)
                    .fontWeight(.medium)
            }
        }
    }
}
