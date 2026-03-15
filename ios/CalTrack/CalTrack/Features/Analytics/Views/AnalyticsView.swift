import SwiftUI
import Charts

enum AnalyticsRange: String, CaseIterable {
    case week = "Hafta"
    case month = "Ay"
    case threeMonths = "3 Ay"
}

struct AnalyticsView: View {
    @State private var selectedRange: AnalyticsRange = .week
    @State private var selectedTab = 0

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

                        // Streak
                        StreakView()
                            .padding(.horizontal)

                        // Calorie Chart
                        CalorieChartView(range: selectedRange)
                            .padding(.horizontal)

                        // Macro Trend
                        MacroTrendView(range: selectedRange)
                            .padding(.horizontal)

                        // Weight Chart
                        WeightChartView(range: selectedRange)
                            .padding(.horizontal)

                        Spacer(minLength: 100)
                    }
                    .padding(.top, 8)
                }
            }
            .background(Color.ctBackground)
            .navigationTitle("Analiz")
        }
    }
}

struct StreakView: View {
    @State private var currentStreak = 7
    @State private var longestStreak = 14

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
    let range: AnalyticsRange

    // Mock data
    var data: [(Date, Double, Double)] {
        let days = range == .week ? 7 : range == .month ? 30 : 90
        return (0..<days).map { i in
            let date = Date().daysAgo(days - 1 - i)
            let consumed = Double.random(in: 1600...2400)
            let goal = 2100.0
            return (date, consumed, goal)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Kalori Takibi")
                .font(.ctHeadline)

            Chart {
                ForEach(data, id: \.0) { item in
                    BarMark(
                        x: .value("Tarih", item.0, unit: .day),
                        y: .value("Kalori", item.1)
                    )
                    .foregroundStyle(item.1 <= item.2 ? Color.ctAccent : Color.ctError)

                    RuleMark(y: .value("Hedef", item.2))
                        .foregroundStyle(Color.secondary.opacity(0.5))
                        .lineStyle(StrokeStyle(dash: [5]))
                }
            }
            .frame(height: 200)
            .chartYAxis {
                AxisMarks(position: .leading)
            }

            // Average
            let avg = data.map(\.1).reduce(0, +) / Double(data.count)
            HStack {
                Text("Ortalama:")
                    .font(.ctCaption)
                    .foregroundStyle(.ctTextSecondary)
                Text("\(Int(avg)) kcal/gün")
                    .font(.ctCaption)
                    .fontWeight(.medium)
            }
        }
        .glassCard(cornerRadius: 16)
    }
}

struct MacroTrendView: View {
    let range: AnalyticsRange

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Makro Trendleri")
                .font(.ctHeadline)

            let days = range == .week ? 7 : range == .month ? 30 : 90
            let data: [(String, Double, Color)] = [
                ("Protein", Double.random(in: 100...180), .ctProtein),
                ("Karb", Double.random(in: 150...250), .ctCarbs),
                ("Yağ", Double.random(in: 50...90), .ctFat)
            ]

            ForEach(data, id: \.0) { item in
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
    let range: AnalyticsRange

    var data: [(Date, Double)] {
        let days = range == .week ? 7 : range == .month ? 30 : 90
        var weight = 75.0
        return (0..<days).map { i in
            let date = Date().daysAgo(days - 1 - i)
            weight += Double.random(in: -0.3...0.2)
            return (date, weight)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Kilo Grafiği")
                .font(.ctHeadline)

            Chart {
                ForEach(data, id: \.0) { item in
                    LineMark(
                        x: .value("Tarih", item.0, unit: .day),
                        y: .value("Kilo", item.1)
                    )
                    .foregroundStyle(Color.ctAccent)
                    .interpolationMethod(.catmullRom)

                    AreaMark(
                        x: .value("Tarih", item.0, unit: .day),
                        y: .value("Kilo", item.1)
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
            .chartYScale(domain: (data.map(\.1).min() ?? 70) - 1...(data.map(\.1).max() ?? 80) + 1)

            if let first = data.first, let last = data.last {
                let change = last.1 - first.1
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
        .glassCard(cornerRadius: 16)
    }
}
