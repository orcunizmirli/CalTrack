import SwiftUI

struct OnboardingFlowView: View {
    @StateObject private var viewModel = OnboardingViewModel()
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 0) {
            // Progress bar
            ProgressView(value: Double(viewModel.currentStep + 1), total: Double(viewModel.totalSteps))
                .tint(.accentColor)
                .padding(.horizontal)
                .padding(.top, 8)

            Text("\(viewModel.currentStep + 1) / \(viewModel.totalSteps)")
                .font(.ctCaption)
                .foregroundColor(.secondary)
                .padding(.top, 4)

            // Content
            TabView(selection: $viewModel.currentStep) {
                PersonalInfoView(viewModel: viewModel)
                    .tag(0)

                BodyMetricsView(viewModel: viewModel)
                    .tag(1)

                BodyFatView(viewModel: viewModel)
                    .tag(2)

                ActivityLevelView(viewModel: viewModel)
                    .tag(3)

                GoalSelectionView(viewModel: viewModel)
                    .tag(4)

                MacroSetupView(viewModel: viewModel)
                    .tag(5)

                PlanSummaryView(viewModel: viewModel)
                    .tag(6)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: viewModel.currentStep)

            // Navigation buttons
            HStack(spacing: 16) {
                if viewModel.currentStep > 0 {
                    Button("Geri") {
                        viewModel.previousStep()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.ctSecondaryBg)
                    .foregroundColor(.primary)
                    .cornerRadius(14)
                }

                Button(viewModel.currentStep == viewModel.totalSteps - 1 ? "Başla" : "Devam") {
                    if viewModel.currentStep == viewModel.totalSteps - 1 {
                        viewModel.saveProfile()
                        appState.completeOnboarding()
                    } else {
                        if viewModel.currentStep == 3 {
                            viewModel.calculateAll()
                        }
                        viewModel.nextStep()
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(14)
                .fontWeight(.semibold)
            }
            .padding(.horizontal)
            .padding(.bottom, 32)
        }
        .background(Color.ctBackground)
    }
}
