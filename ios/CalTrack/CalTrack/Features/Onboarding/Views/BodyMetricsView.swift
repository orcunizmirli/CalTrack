import SwiftUI

struct BodyMetricsView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @State private var hasManuallySetWeight = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Image(systemName: "figure.arms.open")
                        .font(.system(size: 48))
                        .foregroundStyle(.ctAccent)

                    Text("Vücut Ölçülerin")
                        .font(.ctTitle)

                    Text("Boy ve kilo bilgilerin kalori hesaplaması için gerekli")
                        .font(.ctSubheadline)
                        .foregroundStyle(.ctTextSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)

                // Height
                VStack(spacing: 12) {
                    HStack {
                        Text("Boy")
                            .font(.ctHeadline)
                        Spacer()
                        Text("\(Int(viewModel.heightCm)) cm")
                            .font(.ctMacroValue)
                            .foregroundStyle(.ctAccent)
                    }

                    Slider(value: $viewModel.heightCm, in: 120...220, step: 1)
                        .tint(.ctAccent)
                }
                .glassCard(cornerRadius: 14)
                .onChange(of: viewModel.heightCm) { _, newHeight in
                    guard !hasManuallySetWeight else { return }
                    viewModel.weightKg = idealWeight(heightCm: newHeight, gender: viewModel.gender)
                }

                // Weight
                VStack(spacing: 8) {
                    HStack {
                        Text("Kilo")
                            .font(.ctHeadline)
                        Spacer()
                        Text(String(format: "%.1f kg", viewModel.weightKg))
                            .font(.ctMacroValue)
                            .foregroundStyle(.ctAccent)
                    }
                    .padding(.horizontal, 4)

                    RulerPicker(
                        value: $viewModel.weightKg,
                        range: 30...200,
                        step: 0.1,
                        onUserScroll: { hasManuallySetWeight = true }
                    )
                }
                .glassCard(cornerRadius: 14)

                // BMI Display
                let bmi = BodyFatEstimator.bmi(weightKg: viewModel.weightKg, heightCm: viewModel.heightCm)
                VStack(spacing: 8) {
                    HStack {
                        Text("BMI")
                            .font(.ctHeadline)
                        Spacer()
                        Text(String(format: "%.1f", bmi))
                            .font(.ctMacroValue)
                        Text(BodyFatEstimator.bmiCategory(bmi))
                            .font(.ctFootnote)
                            .foregroundStyle(.ctTextSecondary)
                    }

                    // BMI Bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(LinearGradient(
                                    colors: [.blue, .green, .yellow, .orange, .red],
                                    startPoint: .leading, endPoint: .trailing
                                ))
                                .frame(height: 8)

                            let position = min(max((bmi - 15) / 30, 0), 1)
                            Circle()
                                .fill(.white)
                                .frame(width: 16, height: 16)
                                .shadow(radius: 2)
                                .offset(x: geo.size.width * position - 8)
                        }
                    }
                    .frame(height: 16)

                    HStack {
                        Text("15").font(.ctCaption).foregroundStyle(.ctTextSecondary)
                        Spacer()
                        Text("25").font(.ctCaption).foregroundStyle(.ctTextSecondary)
                        Spacer()
                        Text("35").font(.ctCaption).foregroundStyle(.ctTextSecondary)
                        Spacer()
                        Text("45").font(.ctCaption).foregroundStyle(.ctTextSecondary)
                    }
                }
                .glassCard(cornerRadius: 14)
            }
            .padding(.horizontal)
            .padding(.bottom, 100)
        }
        .onAppear {
            if !hasManuallySetWeight {
                viewModel.weightKg = idealWeight(heightCm: viewModel.heightCm, gender: viewModel.gender)
            }
        }
    }

    private func idealWeight(heightCm: Double, gender: Gender) -> Double {
        let heightM = heightCm / 100
        let idealBMI: Double = gender == .male ? 22.5 : 21.5
        return ((idealBMI * heightM * heightM) * 10).rounded() / 10
    }
}
