import SwiftUI

struct PlanSummaryView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Success badge
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 64))
                        .foregroundColor(.ctSuccess)

                    Text("Planın Hazır!")
                        .font(.ctTitle)

                    Text("Hedefin gerçekçi ve ulaşılabilir")
                        .font(.ctSubheadline)
                        .foregroundColor(.ctSuccess)
                }
                .padding(.top, 20)

                // Summary Card
                VStack(spacing: 16) {
                    SummaryRow(icon: "target", label: "Hedef", value: viewModel.goalType.displayName)
                    Divider()
                    SummaryRow(icon: "flame.fill", label: "Günlük Kalori", value: "\(viewModel.dailyCalories) kcal")
                    Divider()
                    SummaryRow(icon: "scalemass.fill", label: "Mevcut Kilo", value: String(format: "%.1f kg", viewModel.weightKg))

                    if viewModel.goalType != .maintain {
                        Divider()
                        SummaryRow(icon: "flag.fill", label: "Hedef Kilo", value: String(format: "%.1f kg", viewModel.targetWeight))
                        Divider()

                        let weeksNeeded = abs(viewModel.targetWeight - viewModel.weightKg) / viewModel.weeklyChangeKg
                        SummaryRow(icon: "calendar", label: "Tahmini Süre", value: "\(Int(weeksNeeded)) hafta")
                    }
                }
                .glassCard(cornerRadius: 14)

                // Macro Summary
                VStack(spacing: 12) {
                    Text("Günlük Makro Hedefleri")
                        .font(.ctHeadline)

                    HStack(spacing: 16) {
                        MacroSummaryItem(name: "Protein", value: "\(viewModel.proteinG)g", color: .ctProtein)
                        MacroSummaryItem(name: "Karb", value: "\(viewModel.carbsG)g", color: .ctCarbs)
                        MacroSummaryItem(name: "Yağ", value: "\(viewModel.fatG)g", color: .ctFat)
                    }
                }
                .glassCard(cornerRadius: 14)

                // Calculation details
                VStack(alignment: .leading, spacing: 8) {
                    Text("Hesaplama Detayları")
                        .font(.ctHeadline)

                    DetailRow(label: "BMR", value: "\(Int(viewModel.bmr)) kcal")
                    DetailRow(label: "Aktivite Çarpanı", value: "×\(String(format: "%.2f", viewModel.activityLevel.multiplier))")
                    DetailRow(label: "TDEE", value: "\(Int(viewModel.tdee)) kcal")

                    if let bf = viewModel.bodyFatPct {
                        DetailRow(label: "Vücut Yağ Oranı", value: String(format: "%%%.1f", bf))
                        DetailRow(label: "Hesaplama Yöntemi", value: "Katch-McArdle")
                    } else {
                        DetailRow(label: "Hesaplama Yöntemi", value: "Mifflin-St Jeor")
                    }
                }
                .glassCard(cornerRadius: 14)

                Text("Tüm değerler daha sonra ayarlardan düzenlenebilir")
                    .font(.ctCaption)
                    .foregroundStyle(.ctTextSecondary)
                    .multilineTextAlignment(.center)
                    .id("bottom")
            }
            .padding(.horizontal)
            .padding(.bottom, 100)
        }
        .onScrollGeometryChange(for: Bool.self) { geo in
            let atBottom = geo.contentOffset.y + geo.containerSize.height >= geo.contentSize.height - 20
            return atBottom
        } action: { _, atBottom in
            if atBottom && !viewModel.hasSeenSummary {
                viewModel.hasSeenSummary = true
            }
        }
    }
}

struct SummaryRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(.ctAccent)
                .frame(width: 24)
            Text(label)
                .font(.ctBody)
                .foregroundStyle(.ctTextSecondary)
            Spacer()
            Text(value)
                .font(.ctHeadline)
        }
    }
}

struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.ctCaption)
                .foregroundStyle(.ctTextSecondary)
            Spacer()
            Text(value)
                .font(.ctCaption)
                .fontWeight(.medium)
        }
    }
}

struct MacroSummaryItem: View {
    let name: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.ctTitle2)
                .foregroundColor(color)
            Text(name)
                .font(.ctCaption)
                .foregroundStyle(.ctTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.1))
        .cornerRadius(10)
    }
}
