import SwiftUI

struct MicroNutrientView: View {
    @State private var nutrients: [MicroNutrient] = MicroNutrientDefaults.defaultRDA(gender: .male, age: 25)
    @Environment(\.dismiss) private var dismiss

    var vitamins: [MicroNutrient] {
        nutrients.filter { $0.id.hasPrefix("vit_") }
    }

    var minerals: [MicroNutrient] {
        nutrients.filter { !$0.id.hasPrefix("vit_") }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                GlassEffectContainer {
                    VStack(spacing: 20) {
                        // Summary
                        HStack(spacing: 16) {
                            MicroSummaryCard(
                                title: "Optimal",
                                count: nutrients.filter { $0.status == .optimal }.count,
                                total: nutrients.count,
                                color: .ctSuccess
                            )
                            MicroSummaryCard(
                                title: "Düşük",
                                count: nutrients.filter { $0.status == .low || $0.status == .deficient }.count,
                                total: nutrients.count,
                                color: .ctWarning
                            )
                            MicroSummaryCard(
                                title: "Fazla",
                                count: nutrients.filter { $0.status == .high || $0.status == .excessive }.count,
                                total: nutrients.count,
                                color: .ctError
                            )
                        }
                        .padding(.horizontal)

                        // Vitamins
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Vitaminler")
                                .font(.ctTitle2)
                                .padding(.horizontal)

                            ForEach(vitamins) { nutrient in
                                MicroNutrientRow(nutrient: nutrient)
                                    .padding(.horizontal)
                            }
                        }

                        // Minerals
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Mineraller")
                                .font(.ctTitle2)
                                .padding(.horizontal)

                            ForEach(minerals) { nutrient in
                                MicroNutrientRow(nutrient: nutrient)
                                    .padding(.horizontal)
                            }
                        }

                        Text("Değerler bugünkü tüketiminize göre hesaplanır.\nRDA (Günlük Önerilen Miktar) yaş ve cinsiyete göre belirlenir.")
                            .font(.ctCaption)
                            .foregroundStyle(.ctTextSecondary)
                            .multilineTextAlignment(.center)
                            .padding()
                    }
                    .padding(.vertical)
                }
            }
            .background(Color.ctBackground)
            .navigationTitle("Mikro Besinler")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kapat") { dismiss() }
                }
            }
        }
    }
}

struct MicroSummaryCard: View {
    let title: String
    let count: Int
    let total: Int
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.ctTitle)
                .foregroundStyle(color)
            Text("/ \(total)")
                .font(.ctCaption)
                .foregroundStyle(.ctTextSecondary)
            Text(title)
                .font(.ctCaption)
                .foregroundStyle(.ctTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .glassClearCard(padding: 12, cornerRadius: 12)
    }
}

struct MicroNutrientRow: View {
    let nutrient: MicroNutrient

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Text(nutrient.name)
                    .font(.ctSubheadline)

                Spacer()

                Text(String(format: "%.1f / %.0f %@",
                           nutrient.currentAmount,
                           nutrient.rdaAmount,
                           nutrient.unit))
                    .font(.ctCaption)
                    .foregroundStyle(.ctTextSecondary)

                Text("\(nutrient.progressPercentage)%")
                    .font(.ctCaption)
                    .fontWeight(.medium)
                    .foregroundStyle(statusColor)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.secondary.opacity(0.15))
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(statusColor)
                        .frame(width: geo.size.width * min(nutrient.progress, 1.0), height: 6)
                }
            }
            .frame(height: 6)
        }
        .padding(.vertical, 4)
    }

    var statusColor: Color {
        switch nutrient.status {
        case .deficient: return .ctError
        case .low: return .ctWarning
        case .optimal: return .ctSuccess
        case .high: return .ctWarning
        case .excessive: return .ctError
        }
    }
}
