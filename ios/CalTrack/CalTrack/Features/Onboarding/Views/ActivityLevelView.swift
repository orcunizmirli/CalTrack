import SwiftUI

struct ActivityLevelView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Image(systemName: "figure.run")
                        .font(.system(size: 48))
                        .foregroundStyle(.ctAccent)

                    Text("Aktivite Seviyesi")
                        .font(.ctTitle)

                    Text("Günlük aktivite seviyeni seç")
                        .font(.ctSubheadline)
                        .foregroundStyle(.ctTextSecondary)
                }
                .padding(.top, 20)

                VStack(spacing: 10) {
                    ForEach(ActivityLevel.allCases, id: \.self) { level in
                        let isActive = viewModel.activityLevel == level
                        Button(action: {
                            withAnimation { viewModel.activityLevel = level }
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: activityIcon(for: level))
                                    .font(.body)
                                    .frame(width: 28)

                                VStack(alignment: .leading, spacing: 1) {
                                    Text(level.displayName)
                                        .font(.ctSubheadline)
                                    Text(level.description)
                                        .font(.ctCaption)
                                        .foregroundStyle(isActive ? .black.opacity(0.6) : .ctTextSecondary)
                                }

                                Spacer()

                                Text("×\(String(format: "%.1f", level.multiplier))")
                                    .font(.ctCaption)
                                    .foregroundStyle(isActive ? .black.opacity(0.6) : .ctTextTertiary)

                                Image(systemName: isActive ? "checkmark.circle.fill" : "circle")
                            }
                            .foregroundStyle(isActive ? .black : .ctTextPrimary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 11)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .glassEffect(isActive ? .regular.tint(.ctAccent) : .regular)
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
