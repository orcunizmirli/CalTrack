import WidgetKit
import SwiftUI

struct MacroProvider: TimelineProvider {
    func placeholder(in context: Context) -> MacroEntry {
        MacroEntry(date: Date(), data: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (MacroEntry) -> Void) {
        completion(MacroEntry(date: Date(), data: WidgetDataManager.load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MacroEntry>) -> Void) {
        let data = WidgetDataManager.load()
        let entry = MacroEntry(date: Date(), data: data)
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

struct MacroEntry: TimelineEntry {
    let date: Date
    let data: WidgetData
}

struct MacroWidgetView: View {
    var entry: MacroEntry

    private var calorieProgress: Double {
        guard entry.data.calorieGoal > 0 else { return 0 }
        return min(entry.data.caloriesConsumed / Double(entry.data.calorieGoal), 1.0)
    }

    private var remaining: Int {
        max(0, entry.data.calorieGoal - Int(entry.data.caloriesConsumed) + Int(entry.data.caloriesBurned))
    }

    var body: some View {
        HStack(spacing: 12) {
            // Calorie ring (left)
            ZStack {
                Circle()
                    .stroke(Color.green.opacity(0.2), lineWidth: 8)

                Circle()
                    .trim(from: 0, to: calorieProgress)
                    .stroke(Color.green, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 1) {
                    Text("\(remaining)")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .minimumScaleFactor(0.5)
                    Text("kalan")
                        .font(.system(size: 8))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 70, height: 70)

            // Macro bars (right)
            VStack(alignment: .leading, spacing: 8) {
                WidgetMacroBar(
                    name: "Protein",
                    current: entry.data.proteinG,
                    goal: entry.data.proteinGoal,
                    color: Color(red: 0.376, green: 0.647, blue: 0.98)
                )

                WidgetMacroBar(
                    name: "Karb",
                    current: entry.data.carbsG,
                    goal: entry.data.carbsGoal,
                    color: Color(red: 0.984, green: 0.573, blue: 0.235)
                )

                WidgetMacroBar(
                    name: "Yağ",
                    current: entry.data.fatG,
                    goal: entry.data.fatGoal,
                    color: Color(red: 0.973, green: 0.443, blue: 0.443)
                )
            }
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct WidgetMacroBar: View {
    let name: String
    let current: Double
    let goal: Int
    let color: Color

    private var progress: Double {
        guard goal > 0 else { return 0 }
        return min(current / Double(goal), 1.0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(name)
                    .font(.system(size: 10, weight: .medium))
                Spacer()
                Text("\(Int(current))/\(goal)g")
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color.opacity(0.2))
                        .frame(height: 4)

                    RoundedRectangle(cornerRadius: 2)
                        .fill(color)
                        .frame(width: geo.size.width * progress, height: 4)
                }
            }
            .frame(height: 4)
        }
    }
}

struct MacroWidget: Widget {
    let kind = "MacroWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MacroProvider()) { entry in
            MacroWidgetView(entry: entry)
        }
        .configurationDisplayName("Makro Takip")
        .description("Kalori ve makro besin takibi")
        .supportedFamilies([.systemMedium])
    }
}
