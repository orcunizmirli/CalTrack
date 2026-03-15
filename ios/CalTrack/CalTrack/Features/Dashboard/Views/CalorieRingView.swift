import SwiftUI

struct CalorieRingView: View {
    let consumed: Double
    let goal: Int
    let burned: Double
    let remaining: Double

    var progress: Double {
        guard goal > 0 else { return 0 }
        return min(consumed / Double(goal), 1.0)
    }

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                // Background ring
                Circle()
                    .stroke(Color.ctAccent.opacity(0.1), lineWidth: 20)
                    .frame(width: 200, height: 200)

                // Progress ring
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        progress > 1.0 ? Color.ctError : Color.ctAccent,
                        style: StrokeStyle(lineWidth: 20, lineCap: .round)
                    )
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-90))
                    .animation(Animation.ctRing, value: progress)
                    .shadow(color: .ctAccent.opacity(0.3), radius: 20)

                // Center text
                VStack(spacing: 4) {
                    Text(String(format: "%.0f", max(remaining, 0)))
                        .font(.ctHero)
                        .foregroundStyle(remaining >= 0 ? .ctTextPrimary : .ctError)

                    Text("Kalan")
                        .font(.ctCaption)
                        .foregroundStyle(.ctTextSecondary)
                }
            }

            // Bottom stats
            HStack(spacing: 32) {
                CalorieStatItem(
                    label: "Hedef",
                    value: "\(goal)",
                    icon: "flag.fill",
                    color: .secondary
                )

                CalorieStatItem(
                    label: "Tüketilen",
                    value: String(format: "%.0f", consumed),
                    icon: "fork.knife",
                    color: .ctAccent
                )

                CalorieStatItem(
                    label: "Yakılan",
                    value: String(format: "%.0f", burned),
                    icon: "flame.fill",
                    color: .orange
                )
            }
        }
        .glassCard(padding: 20, cornerRadius: 20)
    }
}

struct CalorieStatItem: View {
    let label: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .font(.callout)
            Text(value)
                .font(.ctHeadline)
            Text(label)
                .font(.ctCaption)
                .foregroundStyle(.ctTextSecondary)
        }
    }
}
