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
                    .stroke(Color.ctCalories.opacity(0.15), lineWidth: 24)
                    .frame(width: 180, height: 180)

                // Progress ring
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        progress > 1.0 ? Color.ctError : Color.ctCalories,
                        style: StrokeStyle(lineWidth: 24, lineCap: .round)
                    )
                    .frame(width: 180, height: 180)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.8), value: progress)

                // Center text
                VStack(spacing: 4) {
                    Text(String(format: "%.0f", max(remaining, 0)))
                        .font(.ctCalorieDisplay)
                        .foregroundColor(remaining >= 0 ? .primary : .ctError)

                    Text("Kalan")
                        .font(.ctCaption)
                        .foregroundColor(.secondary)
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
                    color: .ctCalories
                )

                CalorieStatItem(
                    label: "Yakılan",
                    value: String(format: "%.0f", burned),
                    icon: "flame.fill",
                    color: .orange
                )
            }
        }
        .padding()
        .background(Color.ctSecondaryBg)
        .cornerRadius(20)
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
                .foregroundColor(color)
                .font(.callout)
            Text(value)
                .font(.ctHeadline)
            Text(label)
                .font(.ctCaption)
                .foregroundColor(.secondary)
        }
    }
}
