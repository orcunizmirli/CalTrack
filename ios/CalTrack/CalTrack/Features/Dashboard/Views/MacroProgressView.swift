import SwiftUI

struct MacroProgressView: View {
    let protein: Double
    let proteinGoal: Int
    let carbs: Double
    let carbsGoal: Int
    let fat: Double
    let fatGoal: Int

    var body: some View {
        HStack(spacing: 12) {
            MacroProgressItem(
                name: "Protein",
                current: protein,
                goal: proteinGoal,
                color: .ctProtein,
                unit: "g"
            )

            MacroProgressItem(
                name: "Karb",
                current: carbs,
                goal: carbsGoal,
                color: .ctCarbs,
                unit: "g"
            )

            MacroProgressItem(
                name: "Yağ",
                current: fat,
                goal: fatGoal,
                color: .ctFat,
                unit: "g"
            )
        }
        .glassCard(cornerRadius: 16)
    }
}

struct MacroProgressItem: View {
    let name: String
    let current: Double
    let goal: Int
    let color: Color
    let unit: String

    private var progress: Double {
        guard goal > 0 else { return 0 }
        return min(current / Double(goal), 1.0)
    }

    private var remaining: Int {
        max(0, goal - Int(current))
    }

    var body: some View {
        VStack(spacing: 8) {
            // Circular progress
            ZStack {
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: 6)
                    .frame(width: 56, height: 56)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(color, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 56, height: 56)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: progress)

                Text("\(Int(current))")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
            }

            Text(name)
                .font(.ctCaption)
                .foregroundStyle(.ctTextSecondary)

            Text("\(remaining)\(unit) kaldı")
                .font(.system(size: 10))
                .foregroundStyle(.ctTextSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}
