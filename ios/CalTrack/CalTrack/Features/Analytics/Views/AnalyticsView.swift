import SwiftUI
import Charts

enum AnalyticsRange: String, CaseIterable {
    case week = "Hafta"
    case month = "Ay"
    case threeMonths = "3 Ay"
}

struct AnalyticsView: View {
    @StateObject private var viewModel = AnalyticsViewModel()
    @State private var selectedRange: AnalyticsRange = .week

    var body: some View {
        NavigationStack {
            ScrollView {
                GlassEffectContainer {
                    VStack(spacing: 16) {
                        // Range selector
                        Picker("Aralık", selection: $selectedRange) {
                            ForEach(AnalyticsRange.allCases, id: \.self) { range in
                                Text(range.rawValue).tag(range)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)

                        if viewModel.isLoading {
                            AnalyticsShimmerView()
                        } else {
                            // Streak
                            StreakView(
                                currentStreak: viewModel.streak.currentStreak,
                                longestStreak: viewModel.streak.longestStreak
                            )
                            .padding(.horizontal)

                            // Calorie Chart
                            CalorieChartView(
                                data: viewModel.calorieData,
                                goal: viewModel.calorieGoal,
                                average: viewModel.avgCalories
                            )
                            .padding(.horizontal)

                            // Macro Trend
                            MacroTrendView(
                                avgProtein: viewModel.avgProtein,
                                avgCarbs: viewModel.avgCarbs,
                                avgFat: viewModel.avgFat
                            )
                            .padding(.horizontal)

                            // Weight Chart
                            WeightChartView(
                                data: viewModel.weightData,
                                change: viewModel.weightChange
                            )
                            .padding(.horizontal)
                        }

                        Spacer(minLength: 100)
                    }
                    .padding(.top, 8)
                }
            }
            .background(Color.ctBackground)
            .navigationTitle("Analiz")
            .task { await viewModel.loadData(range: selectedRange) }
            .onChange(of: selectedRange) { _, newRange in
                Task { await viewModel.loadData(range: newRange) }
            }
        }
    }
}

struct StreakView: View {
    let currentStreak: Int
    let longestStreak: Int

    var body: some View {
        HStack(spacing: 16) {
            VStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .font(.title)
                    .foregroundStyle(.ctAccent)
                Text("\(currentStreak)")
                    .font(.ctTitle)
                Text("Günlük Seri")
                    .font(.ctCaption)
                    .foregroundStyle(.ctTextSecondary)
            }
            .frame(maxWidth: .infinity)

            Divider().frame(height: 60)

            VStack(spacing: 4) {
                Image(systemName: "trophy.fill")
                    .font(.title)
                    .foregroundStyle(.ctWarning)
                Text("\(longestStreak)")
                    .font(.ctTitle)
                Text("En Uzun Seri")
                    .font(.ctCaption)
                    .foregroundStyle(.ctTextSecondary)
            }
            .frame(maxWidth: .infinity)
        }
        .glassCard(cornerRadius: 16)
    }
}

struct CalorieChartView: View {
    let data: [CalorieDayData]
    let goal: Double
    let average: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Kalori Takibi")
                .font(.ctHeadline)

            if data.isEmpty {
                Text("Henüz veri yok")
                    .font(.ctSubheadline)
                    .foregroundStyle(.ctTextSecondary)
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
            } else {
                Chart {
                    ForEach(data) { item in
                        BarMark(
                            x: .value("Tarih", item.date, unit: .day),
                            y: .value("Kalori", item.calories)
                        )
                        .foregroundStyle(item.calories <= goal ? Color.ctAccent : Color.ctError)
                    }

                    RuleMark(y: .value("Hedef", goal))
                        .foregroundStyle(Color.secondary.opacity(0.5))
                        .lineStyle(StrokeStyle(dash: [5]))
                }
                .frame(height: 200)
                .chartYAxis {
                    AxisMarks(position: .leading)
                }

                HStack {
                    Text("Ortalama:")
                        .font(.ctCaption)
                        .foregroundStyle(.ctTextSecondary)
                    Text("\(Int(average)) kcal/gün")
                        .font(.ctCaption)
                        .fontWeight(.medium)
                }
            }
        }
        .glassCard(cornerRadius: 16)
    }
}

struct MacroTrendView: View {
    let avgProtein: Double
    let avgCarbs: Double
    let avgFat: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Makro Trendleri")
                .font(.ctHeadline)

            let items: [(String, Double, Color)] = [
                ("Protein", avgProtein, .ctProtein),
                ("Karb", avgCarbs, .ctCarbs),
                ("Yağ", avgFat, .ctFat)
            ]

            ForEach(items, id: \.0) { item in
                HStack {
                    Circle().fill(item.2).frame(width: 8, height: 8)
                    Text(item.0)
                        .font(.ctSubheadline)
                    Spacer()
                    Text("\(Int(item.1))g ort.")
                        .font(.ctSubheadline)
                        .foregroundStyle(.ctTextSecondary)
                }
            }
        }
        .glassCard(cornerRadius: 16)
    }
}

struct WeightChartView: View {
    let data: [WeightDayData]
    let change: Double?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Kilo Grafiği")
                .font(.ctHeadline)

            if data.isEmpty {
                Text("Henüz kilo verisi yok")
                    .font(.ctSubheadline)
                    .foregroundStyle(.ctTextSecondary)
                    .frame(height: 180)
                    .frame(maxWidth: .infinity)
            } else {
                Chart {
                    ForEach(data) { item in
                        LineMark(
                            x: .value("Tarih", item.date, unit: .day),
                            y: .value("Kilo", item.weightKg)
                        )
                        .foregroundStyle(Color.ctAccent)
                        .interpolationMethod(.catmullRom)

                        AreaMark(
                            x: .value("Tarih", item.date, unit: .day),
                            y: .value("Kilo", item.weightKg)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.ctAccent.opacity(0.3), Color.ctAccent.opacity(0.0)],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                        .interpolationMethod(.catmullRom)
                    }
                }
                .frame(height: 180)
                .chartYScale(
                    domain: (data.map(\.weightKg).min() ?? 70) - 1...(data.map(\.weightKg).max() ?? 80) + 1
                )

                if let change {
                    HStack {
                        Text("Değişim:")
                            .font(.ctCaption)
                            .foregroundStyle(.ctTextSecondary)
                        Text(String(format: "%+.1f kg", change))
                            .font(.ctCaption)
                            .fontWeight(.medium)
                            .foregroundColor(change < 0 ? .ctSuccess : .ctWarning)
                    }
                }
            }
        }
        .glassCard(cornerRadius: 16)
    }
}
