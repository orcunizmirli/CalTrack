import SwiftUI

struct WatchMealsView: View {
    @EnvironmentObject var connectivity: WatchConnectivityManager

    var body: some View {
        List {
            if connectivity.todayMeals.isEmpty {
                Text("Henüz yemek eklenmedi")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            } else {
                ForEach(connectivity.todayMeals, id: \.name) { meal in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(meal.name)
                            .font(.system(size: 13, weight: .medium))
                            .lineLimit(1)

                        HStack(spacing: 4) {
                            Text("\(Int(meal.calories)) kcal")
                                .font(.system(size: 11))
                                .foregroundStyle(.green)

                            Text("P:\(Int(meal.proteinG))g")
                                .font(.system(size: 10))
                                .foregroundStyle(.blue)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .navigationTitle("Yemekler")
    }
}
