import SwiftUI

struct GoalSelectionView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Image(systemName: "target")
                        .font(.system(size: 48))
                        .foregroundColor(.accentColor)

                    Text("Hedefini Belirle")
                        .font(.ctTitle)

                    Text("Ana hedefin nedir?")
                        .font(.ctSubheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 20)

                // Goal Type Selection
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
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
                    VStack(spacing: 12) {
                        HStack {
                            Text("Hedef Kilo")
                                .font(.ctHeadline)
                            Spacer()
                            Text(String(format: "%.1f kg", viewModel.targetWeight))
                                .font(.ctMacroValue)
                                .foregroundColor(.accentColor)
                        }

                        Slider(value: $viewModel.targetWeight, in: 35...180, step: 0.5)
                            .tint(.accentColor)

                        let diff = viewModel.targetWeight - viewModel.weightKg
                        Text(diff > 0 ? "+\(String(format: "%.1f", diff)) kg almak" : "\(String(format: "%.1f", abs(diff))) kg vermek")
                            .font(.ctFootnote)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.ctSecondaryBg)
                    .cornerRadius(14)

                    // Weekly change rate
                    VStack(spacing: 12) {
                        HStack {
                            Text("Haftalık Değişim Hızı")
                                .font(.ctHeadline)
                            Spacer()
                            Text(String(format: "%.2f kg/hafta", viewModel.weeklyChangeKg))
                                .font(.ctSubheadline)
                                .foregroundColor(.accentColor)
                        }

                        HStack(spacing: 8) {
                            ForEach([0.25, 0.5, 0.75, 1.0], id: \.self) { rate in
                                Button(action: { viewModel.weeklyChangeKg = rate }) {
                                    Text("\(String(format: "%.2f", rate))")
                                        .font(.ctFootnote)
                                        .fontWeight(.medium)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(viewModel.weeklyChangeKg == rate ? Color.accentColor : Color.ctSecondaryBg)
                                        .foregroundColor(viewModel.weeklyChangeKg == rate ? .white : .primary)
                                        .cornerRadius(8)
                                }
                            }
                        }

                        HStack {
                            Text("Yavaş & Sağlıklı")
                                .font(.ctCaption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("Hızlı & Agresif")
                                .font(.ctCaption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color.ctSecondaryBg)
                    .cornerRadius(14)
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
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundColor(isSelected ? .accentColor : .secondary)

                Text(title)
                    .font(.ctHeadline)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background(isSelected ? Color.accentColor.opacity(0.15) : Color.ctSecondaryBg)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
            )
        }
    }
}
