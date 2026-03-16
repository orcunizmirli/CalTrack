import SwiftUI
import WidgetKit

struct WaterTrackerView: View {
    @AppStorage("today_water_ml", store: UserDefaults(suiteName: WidgetDataManager.appGroupID))
    private var totalWaterMl: Int = 0

    @AppStorage("today_water_date", store: UserDefaults(suiteName: WidgetDataManager.appGroupID))
    private var waterDateString: String = ""

    let waterGoal = 2500 // ml

    var progress: Double {
        min(Double(totalWaterMl) / Double(waterGoal), 1.0)
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "drop.fill")
                    .foregroundColor(.blue)
                Text("Su Tüketimi")
                    .font(.ctHeadline)
                Spacer()
                Text("\(totalWaterMl) / \(waterGoal) ml")
                    .font(.ctSubheadline)
                    .foregroundStyle(.ctTextSecondary)
            }

            // Liquid wave progress bar
            LiquidWaterProgress(progress: progress)

            // Quick add buttons
            HStack(spacing: 8) {
                ForEach([200, 250, 330, 500], id: \.self) { amount in
                    Button(action: {
                        withAnimation { addWater(amount) }
                    }) {
                        Text("+\(amount)ml")
                            .font(.ctCaption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(8)
                    }
                }

                Spacer()

                if totalWaterMl > 0 {
                    Button(action: {
                        withAnimation { totalWaterMl = max(0, totalWaterMl - 200) }
                        syncWidgetData()
                    }) {
                        Image(systemName: "minus.circle")
                            .foregroundStyle(.ctTextSecondary)
                    }
                }
            }
        }
        .glassCard()
        .onAppear { resetIfNewDay() }
    }

    private func addWater(_ amount: Int) {
        totalWaterMl += amount
        syncWidgetData()
    }

    private func resetIfNewDay() {
        let today = Date().formatted(date: .numeric, time: .omitted)
        if waterDateString != today {
            totalWaterMl = 0
            waterDateString = today
        }
    }

    private func syncWidgetData() {
        var data = WidgetDataManager.load()
        data.waterMl = totalWaterMl
        data.waterGoal = waterGoal
        data.lastUpdated = Date()
        WidgetDataManager.save(data)
        WidgetCenter.shared.reloadTimelines(ofKind: "WaterWidget")
        WidgetCenter.shared.reloadTimelines(ofKind: "InteractiveWaterWidget")
    }
}
