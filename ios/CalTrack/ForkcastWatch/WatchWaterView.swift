import SwiftUI

struct WatchWaterView: View {
    @EnvironmentObject var connectivity: WatchConnectivityManager
    @State private var selectedAmount: Int = 250

    let amounts = [100, 150, 200, 250, 330, 500]

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Current status
                Image(systemName: "drop.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(.blue)

                Text("\(connectivity.waterMl) ml")
                    .font(.system(size: 20, weight: .bold, design: .rounded))

                Text("Hedef: \(connectivity.waterGoal) ml")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)

                Divider()

                // Digital Crown amount selector
                Text("Eklenecek: \(selectedAmount) ml")
                    .font(.system(size: 14, weight: .medium))

                Picker("Miktar", selection: $selectedAmount) {
                    ForEach(amounts, id: \.self) { amount in
                        Text("\(amount) ml").tag(amount)
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 60)

                // Add button
                Button(action: {
                    connectivity.addWater(ml: selectedAmount)
                }) {
                    HStack {
                        Image(systemName: "plus")
                        Text("Ekle")
                    }
                    .frame(maxWidth: .infinity)
                }
                .tint(.blue)
            }
        }
        .navigationTitle("Su")
    }
}
