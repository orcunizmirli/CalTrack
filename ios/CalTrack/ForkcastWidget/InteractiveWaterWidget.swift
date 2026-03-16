import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Add Water Intent

struct AddWaterIntent: AppIntent {
    static var title: LocalizedStringResource = "Su Ekle"
    static var description = IntentDescription("Forkcast'te su tüketimini artır")

    @Parameter(title: "Miktar (ml)")
    var amount: Int

    init() {
        self.amount = 250
    }

    init(amount: Int) {
        self.amount = amount
    }

    func perform() async throws -> some IntentResult {
        WidgetDataManager.update { data in
            data.waterMl += amount
            data.lastUpdated = Date()
        }

        // Reload widget timelines
        WidgetCenter.shared.reloadTimelines(ofKind: "InteractiveWaterWidget")
        WidgetCenter.shared.reloadTimelines(ofKind: "WaterWidget")

        return .result()
    }
}

// MARK: - Open AI Scan Intent

struct OpenAIScanIntent: AppIntent {
    static var title: LocalizedStringResource = "AI Tarama Aç"
    static var description = IntentDescription("Forkcast AI yemek tarama ekranını aç")
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        return .result()
    }
}

// MARK: - Interactive Water Widget

struct InteractiveWaterProvider: TimelineProvider {
    func placeholder(in context: Context) -> InteractiveWaterEntry {
        InteractiveWaterEntry(date: Date(), data: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (InteractiveWaterEntry) -> Void) {
        completion(InteractiveWaterEntry(date: Date(), data: WidgetDataManager.load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<InteractiveWaterEntry>) -> Void) {
        let data = WidgetDataManager.load()
        let entry = InteractiveWaterEntry(date: Date(), data: data)
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date().addingTimeInterval(900)
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

struct InteractiveWaterEntry: TimelineEntry {
    let date: Date
    let data: WidgetData
}

struct InteractiveWaterWidgetView: View {
    var entry: InteractiveWaterEntry

    private var progress: Double {
        guard entry.data.waterGoal > 0 else { return 0 }
        return min(Double(entry.data.waterMl) / Double(entry.data.waterGoal), 1.0)
    }

    var body: some View {
        VStack(spacing: 8) {
            // Header
            HStack {
                Image(systemName: "drop.fill")
                    .foregroundStyle(.blue)
                Text("\(entry.data.waterMl) ml")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                Spacer()
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.blue.opacity(0.2))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.blue)
                        .frame(width: geo.size.width * progress, height: 8)
                }
            }
            .frame(height: 8)

            // Quick add buttons
            HStack(spacing: 6) {
                Button(intent: AddWaterIntent(amount: 200)) {
                    Text("+200ml")
                        .font(.system(size: 11, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.15))
                        .foregroundStyle(.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)

                Button(intent: AddWaterIntent(amount: 330)) {
                    Text("+330ml")
                        .font(.system(size: 11, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.15))
                        .foregroundStyle(.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)

                Button(intent: AddWaterIntent(amount: 500)) {
                    Text("+500ml")
                        .font(.system(size: 11, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.15))
                        .foregroundStyle(.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
            }

            // AI Scan deep link
            Button(intent: OpenAIScanIntent()) {
                HStack(spacing: 4) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 10))
                    Text("AI Tara")
                        .font(.system(size: 11, weight: .medium))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(Color.green.opacity(0.15))
                .foregroundStyle(.green)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .buttonStyle(.plain)
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct InteractiveWaterWidget: Widget {
    let kind = "InteractiveWaterWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: InteractiveWaterProvider()) { entry in
            InteractiveWaterWidgetView(entry: entry)
        }
        .configurationDisplayName("Hızlı Su Ekle")
        .description("Widget üzerinden hızlıca su ekle")
        .supportedFamilies([.systemMedium])
    }
}
