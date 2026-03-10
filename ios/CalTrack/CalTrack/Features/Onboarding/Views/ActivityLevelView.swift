import SwiftUI

struct ActivityLevelView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Image(systemName: "figure.run")
                        .font(.system(size: 48))
                        .foregroundColor(.accentColor)

                    Text("Aktivite Seviyesi")
                        .font(.ctTitle)

                    Text("Günlük aktivite seviyeni seç")
                        .font(.ctSubheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 20)

                VStack(spacing: 10) {
                    ForEach(ActivityLevel.allCases, id: \.self) { level in
                        Button(action: {
                            withAnimation { viewModel.activityLevel = level }
                        }) {
                            HStack(spacing: 14) {
                                Image(systemName: activityIcon(for: level))
                                    .font(.title2)
                                    .foregroundColor(viewModel.activityLevel == level ? .accentColor : .secondary)
                                    .frame(width: 40)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(level.displayName)
                                        .font(.ctHeadline)
                                        .foregroundColor(.primary)
                                    Text(level.description)
                                        .font(.ctCaption)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                Text("×\(String(format: "%.2f", level.multiplier))")
                                    .font(.ctFootnote)
                                    .foregroundColor(.secondary)

                                Image(systemName: viewModel.activityLevel == level ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(viewModel.activityLevel == level ? .accentColor : .secondary)
                            }
                            .padding()
                            .background(viewModel.activityLevel == level ? Color.accentColor.opacity(0.1) : Color.ctSecondaryBg)
                            .cornerRadius(14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(viewModel.activityLevel == level ? Color.accentColor : Color.clear, lineWidth: 1.5)
                            )
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 100)
        }
    }

    private func activityIcon(for level: ActivityLevel) -> String {
        switch level {
        case .sedentary: return "figure.seated.seatbelt"
        case .light: return "figure.walk"
        case .moderate: return "figure.run"
        case .active: return "figure.highintensity.intervaltraining"
        case .veryActive: return "figure.strengthtraining.traditional"
        }
    }
}
