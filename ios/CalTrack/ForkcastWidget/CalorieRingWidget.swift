import WidgetKit
import SwiftUI

struct CalorieRingProvider: TimelineProvider {
    func placeholder(in context: Context) -> CalorieRingEntry {
        CalorieRingEntry(date: Date(), data: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (CalorieRingEntry) -> Void) {
        completion(CalorieRingEntry(date: Date(), data: WidgetDataManager.load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CalorieRingEntry>) -> Void) {
        let data = WidgetDataManager.load()
        let entry = CalorieRingEntry(date: Date(), data: data)
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

struct CalorieRingEntry: TimelineEntry {
    let date: Date
    let data: WidgetData
}

struct CalorieRingWidgetView: View {
    var entry: CalorieRingEntry

    private var progress: Double {
        guard entry.data.calorieGoal > 0 else { return 0 }
        return min(entry.data.caloriesConsumed / Double(entry.data.calorieGoal), 1.0)
    }

    private var remaining: Int {
        max(0, entry.data.calorieGoal - Int(entry.data.caloriesConsumed) + Int(entry.data.caloriesBurned))
    }

    var body: some View {
        ZStack {
            // Ring
            Circle()
                .stroke(Color.green.opacity(0.2), lineWidth: 10)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(Color.green, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .rotationEffect(.degrees(-90))

            // Center
            VStack(spacing: 2) {
                Text("\(remaining)")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .minimumScaleFactor(0.5)
                Text("kalan")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct CalorieRingWidget: Widget {
    let kind = "CalorieRingWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CalorieRingProvider()) { entry in
            CalorieRingWidgetView(entry: entry)
        }
        .configurationDisplayName("Kalori Halkası")
        .description("Günlük kalori hedefini takip et")
        .supportedFamilies([.systemSmall])
    }
}
