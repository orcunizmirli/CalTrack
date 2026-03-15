import SwiftUI

struct GoalSelectionView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Image(systemName: "target")
                        .font(.system(size: 48))
                        .foregroundStyle(.ctAccent)

                    Text("Hedefini Belirle")
                        .font(.ctTitle)

                    Text("Ana hedefin nedir?")
                        .font(.ctSubheadline)
                        .foregroundStyle(.ctTextSecondary)
                }
                .padding(.top, 20)

                // Goal Type Selection
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(GoalType.allCases, id: \.self) { goal in
                        GoalCard(
                            title: goal.displayName,
                            icon: goal.icon,
                            isSelected: viewModel.goalType == goal
                        ) {
                            withAnimation { viewModel.goalType = goal }
                        }
                    }
                }

                // Target Weight (for weight-related goals)
                if viewModel.goalType != .maintain {
                    VStack(spacing: 8) {
                        HStack {
                            Text("Hedef Kilo")
                                .font(.ctHeadline)
                            Spacer()
                            Text(String(format: "%.1f kg", viewModel.targetWeight))
                                .font(.ctMacroValue)
                                .foregroundStyle(.ctAccent)
                        }
                        .padding(.horizontal, 4)

                        RulerPicker(
                            value: $viewModel.targetWeight,
                            range: 35...180,
                            step: 0.1
                        )

                        let diff = viewModel.targetWeight - viewModel.weightKg
                        Text(diff > 0 ? "+\(String(format: "%.1f", diff)) kg almak" : "\(String(format: "%.1f", abs(diff))) kg vermek")
                            .font(.ctFootnote)
                            .foregroundStyle(.ctTextSecondary)
                    }
                    .glassCard(cornerRadius: 14)

                    // Weekly change rate
                    VStack(spacing: 8) {
                        HStack {
                            Text("Haftalık Hız")
                                .font(.ctHeadline)
                            Spacer()
                            Text(String(format: "%.2f kg", viewModel.weeklyChangeKg))
                                .font(.ctMacroValue)
                                .foregroundStyle(.ctAccent)
                        }

                        Slider(
                            value: $viewModel.weeklyChangeKg,
                            in: 0.10...1.0,
                            step: 0.05
                        )
                        .tint(.ctAccent)

                        HStack {
                            Text("Yavaş & Sağlıklı")
                                .font(.ctCaption)
                                .foregroundStyle(.ctTextSecondary)
                            Spacer()
                            Text("Hızlı")
                                .font(.ctCaption)
                                .foregroundStyle(.ctTextSecondary)
                        }
                    }
                    .glassCard(cornerRadius: 14)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 100)
        }
    }
}

struct GoalCard: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 16))

                Text(title)
                    .font(.ctSubheadline)
            }
            .foregroundStyle(isSelected ? .black : .ctTextPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .glassEffect(isSelected ? .regular.tint(.ctAccent) : .regular)
        }
    }
}
