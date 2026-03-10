import SwiftUI

struct BodyMetricsView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Image(systemName: "figure.arms.open")
                        .font(.system(size: 48))
                        .foregroundColor(.accentColor)

                    Text("Vücut Ölçülerin")
                        .font(.ctTitle)

                    Text("Boy ve kilo bilgilerin kalori hesaplaması için gerekli")
                        .font(.ctSubheadline)
                        .foregroundColor(.secondary)
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
                            .foregroundColor(.accentColor)
                    }

                    Slider(value: $viewModel.heightCm, in: 120...220, step: 1)
                        .tint(.accentColor)
                }
                .padding()
                .background(Color.ctSecondaryBg)
                .cornerRadius(14)

                // Weight
                VStack(spacing: 12) {
                    HStack {
                        Text("Kilo")
                            .font(.ctHeadline)
                        Spacer()
                        Text(String(format: "%.1f kg", viewModel.weightKg))
                            .font(.ctMacroValue)
                            .foregroundColor(.accentColor)
                    }

                    Slider(value: $viewModel.weightKg, in: 30...200, step: 0.5)
                        .tint(.accentColor)
                }
                .padding()
                .background(Color.ctSecondaryBg)
                .cornerRadius(14)

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
                            .foregroundColor(.secondary)
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
                        Text("15").font(.ctCaption).foregroundColor(.secondary)
                        Spacer()
                        Text("25").font(.ctCaption).foregroundColor(.secondary)
                        Spacer()
                        Text("35").font(.ctCaption).foregroundColor(.secondary)
                        Spacer()
                        Text("45").font(.ctCaption).foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color.ctSecondaryBg)
                .cornerRadius(14)
            }
            .padding(.horizontal)
            .padding(.bottom, 100)
        }
    }
}
