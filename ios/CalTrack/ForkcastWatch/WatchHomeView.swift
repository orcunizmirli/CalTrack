import SwiftUI

struct WatchHomeView: View {
    @EnvironmentObject var connectivity: WatchConnectivityManager

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    // Calorie Ring
                    WatchCalorieRing(
                        consumed: connectivity.caloriesConsumed,
                        goal: connectivity.calorieGoal,
                        remaining: connectivity.caloriesRemaining
                    )

                    // Quick Stats
                    HStack(spacing: 8) {
                        WatchStatCard(label: "Protein", value: "\(Int(connectivity.proteinG))g", color: .blue)
                        WatchStatCard(label: "Karb", value: "\(Int(connectivity.carbsG))g", color: .orange)
                        WatchStatCard(label: "Yağ", value: "\(Int(connectivity.fatG))g", color: .red)
                    }

                    // Water tracker
                    NavigationLink(destination: WatchWaterView()) {
                        HStack {
                            Image(systemName: "drop.fill")
                                .foregroundStyle(.blue)
                            Text("\(connectivity.waterMl) ml")
                                .font(.system(size: 14, weight: .medium))
                            Spacer()
                            Text("\(connectivity.waterGoal) ml")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                        }
                        .padding(8)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)

                    // Today's meals
                    NavigationLink(destination: WatchMealsView()) {
                        HStack {
                            Image(systemName: "fork.knife")
                                .foregroundStyle(.green)
                            Text("Bugünkü Yemekler")
                                .font(.system(size: 14, weight: .medium))
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                        }
                        .padding(8)
                        .background(Color.green.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 4)
            }
            .navigationTitle("Forkcast")
        }
    }
}

// MARK: - Watch Calorie Ring

struct WatchCalorieRing: View {
    let consumed: Double
    let goal: Int
    let remaining: Double

    private var progress: Double {
        guard goal > 0 else { return 0 }
        return min(consumed / Double(goal), 1.0)
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.green.opacity(0.2), lineWidth: 8)
                .frame(width: 100, height: 100)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(Color.green, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .frame(width: 100, height: 100)
                .rotationEffect(.degrees(-90))

            VStack(spacing: 2) {
                Text("\(Int(max(remaining, 0)))")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                Text("kalan")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Watch Stat Card

struct WatchStatCard: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 9))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}
