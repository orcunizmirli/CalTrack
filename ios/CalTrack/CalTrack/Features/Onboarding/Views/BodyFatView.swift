import SwiftUI

struct BodyFatView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Image(systemName: "percent")
                        .font(.system(size: 48))
                        .foregroundStyle(.ctAccent)

                    Text("Vücut Yağ Oranı")
                        .font(.ctTitle)

                    Text("Yağ oranını bilmek kalori hesabını daha doğru yapar. Bilmiyorsan tahmin edebiliriz.")
                        .font(.ctSubheadline)
                        .foregroundStyle(.ctTextSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)

                // Method Selection
                VStack(spacing: 8) {
                    ForEach(OnboardingViewModel.BodyFatMethod.allCases, id: \.self) { method in
                        Button(action: {
                            withAnimation { viewModel.bodyFatMethod = method }
                            if method == .bmi {
                                viewModel.bodyFatPct = BodyFatEstimator.bmiBasedEstimate(
                                    gender: viewModel.gender,
                                    weightKg: viewModel.weightKg,
                                    heightCm: viewModel.heightCm,
                                    age: viewModel.age
                                )
                            }
                        }) {
                            let isActive = viewModel.bodyFatMethod == method
                            HStack {
                                Text(method.rawValue)
                                    .font(.ctSubheadline)
                                Spacer()
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

                // Method-specific inputs
                switch viewModel.bodyFatMethod {
                case .manual:
                    manualInput
                case .usNavy:
                    usNavyInput
                case .bmi:
                    bmiResult
                case .none:
                    noBodyFatView
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 100)
        }
    }

    private var manualInput: some View {
        VStack(spacing: 6) {
            HStack {
                Text("Yağ Oranı")
                    .font(.ctHeadline)
                Spacer()
                Text(String(format: "%%%.\(1)f", viewModel.bodyFatPct ?? 20))
                    .font(.ctMacroValue)
                    .foregroundStyle(.ctAccent)
            }

            Slider(value: Binding(
                get: { viewModel.bodyFatPct ?? 20 },
                set: { viewModel.bodyFatPct = $0 }
            ), in: 3...60, step: 0.5)
            .tint(.ctAccent)

            if let bf = viewModel.bodyFatPct {
                Text(BodyFatEstimator.bodyFatCategory(gender: viewModel.gender, bodyFatPct: bf))
                    .font(.ctCaption)
                    .foregroundStyle(.ctTextSecondary)
            }
        }
        .glassCard(padding: 14, cornerRadius: 14)
    }

    private var usNavyInput: some View {
        VStack(spacing: 12) {
            Text("Vücut Ölçüleri")
                .font(.ctHeadline)

            MeasurementSlider(label: "Bel", value: $viewModel.waistCm, range: 50...150, unit: "cm")
            MeasurementSlider(label: "Boyun", value: $viewModel.neckCm, range: 25...60, unit: "cm")

            if viewModel.gender == .female {
                MeasurementSlider(label: "Kalça", value: $viewModel.hipCm, range: 60...160, unit: "cm")
            }

            Button("Hesapla") {
                viewModel.bodyFatPct = BodyFatEstimator.usNavyMethod(
                    gender: viewModel.gender,
                    heightCm: viewModel.heightCm,
                    waistCm: viewModel.waistCm,
                    neckCm: viewModel.neckCm,
                    hipCm: viewModel.gender == .female ? viewModel.hipCm : nil
                )
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(Color.ctAccent)
            .foregroundStyle(.black)
            .font(.ctSubheadline)
            .fontWeight(.semibold)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            if let bf = viewModel.bodyFatPct {
                HStack(spacing: 4) {
                    Text("Tahmin:")
                        .font(.ctSubheadline)
                    Text(String(format: "%%%.\(1)f", bf))
                        .font(.ctMacroValue)
                        .foregroundStyle(.ctAccent)
                    Text(BodyFatEstimator.bodyFatCategory(gender: viewModel.gender, bodyFatPct: bf))
                        .font(.ctCaption)
                        .foregroundStyle(.ctTextSecondary)
                }
            }
        }
        .glassCard(padding: 14, cornerRadius: 14)
    }

    private var bmiResult: some View {
        VStack(spacing: 6) {
            if let bf = viewModel.bodyFatPct {
                HStack {
                    Text("BMI Tahmin")
                        .font(.ctHeadline)
                    Spacer()
                    Text(String(format: "%%%.\(1)f", bf))
                        .font(.ctMacroValue)
                        .foregroundStyle(.ctAccent)
                    Text(BodyFatEstimator.bodyFatCategory(gender: viewModel.gender, bodyFatPct: bf))
                        .font(.ctCaption)
                        .foregroundStyle(.ctTextSecondary)
                }

                Text("Tahminidir. Ölçüm yöntemi daha doğru sonuç verir.")
                    .font(.ctCaption)
                    .foregroundStyle(.ctTextTertiary)
            }
        }
        .glassCard(padding: 14, cornerRadius: 14)
    }

    private var noBodyFatView: some View {
        HStack(spacing: 10) {
            Image(systemName: "info.circle")
                .font(.body)
                .foregroundStyle(.ctTextSecondary)
            Text("Sorun değil! Yağ oranı olmadan da hesaplama yapabiliriz.")
                .font(.ctFootnote)
                .foregroundStyle(.ctTextSecondary)
        }
        .glassCard(padding: 12, cornerRadius: 12)
    }
}

struct MeasurementSlider: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let unit: String

    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Text(label)
                    .font(.ctSubheadline)
                Spacer()
                Text("\(Int(value)) \(unit)")
                    .font(.ctHeadline)
                    .foregroundStyle(.ctAccent)
            }
            Slider(value: $value, in: range, step: 1)
                .tint(.ctAccent)
        }
    }
}
