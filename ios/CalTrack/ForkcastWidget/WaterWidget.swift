import WidgetKit
import SwiftUI

struct WaterProvider: TimelineProvider {
    func placeholder(in context: Context) -> WaterEntry {
        WaterEntry(date: Date(), data: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (WaterEntry) -> Void) {
        completion(WaterEntry(date: Date(), data: WidgetDataManager.load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WaterEntry>) -> Void) {
        let data = WidgetDataManager.load()
        let entry = WaterEntry(date: Date(), data: data)
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

struct WaterEntry: TimelineEntry {
    let date: Date
    let data: WidgetData
}

struct WaterWidgetView: View {
    var entry: WaterEntry

    private var progress: Double {
        guard entry.data.waterGoal > 0 else { return 0 }
        return min(Double(entry.data.waterMl) / Double(entry.data.waterGoal), 1.0)
    }

    private var glasses: Int {
        entry.data.waterMl / 250
    }

    var body: some View {
        VStack(spacing: 8) {
            // Water drop icon
            Image(systemName: "drop.fill")
                .font(.system(size: 28))
                .foregroundStyle(.blue)

            // Amount
            Text("\(entry.data.waterMl)")
                .font(.system(size: 20, weight: .bold, design: .rounded))
            Text("/ \(entry.data.waterGoal) ml")
                .font(.system(size: 10))
                .foregroundStyle(.secondary)

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.blue.opacity(0.2))
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.blue)
                        .frame(width: geo.size.width * progress, height: 6)
                }
            }
            .frame(height: 6)

            // Glass count
            Text("🥛 ×\(glasses)")
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct WaterWidget: Widget {
    let kind = "WaterWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WaterProvider()) { entry in
            WaterWidgetView(entry: entry)
        }
        .configurationDisplayName("Su Takibi")
        .description("Günlük su tüketimini takip et")
        .supportedFamilies([.systemSmall])
    }
}
