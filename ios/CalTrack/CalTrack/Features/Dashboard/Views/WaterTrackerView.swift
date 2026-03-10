import SwiftUI

struct WaterTrackerView: View {
    @State private var totalWaterMl: Int = 0
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
                    .foregroundColor(.secondary)
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.blue.opacity(0.15))
                        .frame(height: 12)

                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.blue)
                        .frame(width: geo.size.width * progress, height: 12)
                        .animation(.easeInOut, value: totalWaterMl)
                }
            }
            .frame(height: 12)

            // Quick add buttons
            HStack(spacing: 8) {
                ForEach([200, 250, 330, 500], id: \.self) { amount in
                    Button(action: {
                        withAnimation { totalWaterMl += amount }
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
                    }) {
                        Image(systemName: "minus.circle")
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color.ctSecondaryBg)
        .cornerRadius(14)
    }
}
