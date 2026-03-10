import SwiftUI

struct BodyFatView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Image(systemName: "percent")
                        .font(.system(size: 48))
                        .foregroundColor(.accentColor)

                    Text("Vücut Yağ Oranı")
                        .font(.ctTitle)

                    Text("Yağ oranını bilmek kalori hesabını daha doğru yapar. Bilmiyorsan tahmin edebiliriz.")
                        .font(.ctSubheadline)
                        .foregroundColor(.secondary)
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
                            HStack {
                                Text(method.rawValue)
                                    .font(.ctBody)
                                Spacer()
                                Image(systemName: viewModel.bodyFatMethod == method ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(viewModel.bodyFatMethod == method ? .accentColor : .secondary)
                            }
                            .padding()
                            .background(viewModel.bodyFatMethod == method ? Color.accentColor.opacity(0.1) : Color.ctSecondaryBg)
                            .cornerRadius(12)
                        }
                        .foregroundColor(.primary)
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
        VStack(spacing: 12) {
            Text("Yağ Oranını Gir")
                .font(.ctHeadline)

            HStack {
                Spacer()
                Text(String(format: "%%%.1f", viewModel.bodyFatPct ?? 20))
                    .font(.ctCalorieDisplay)
                    .foregroundColor(.accentColor)
                Spacer()
            }

            Slider(value: Binding(
                get: { viewModel.bodyFatPct ?? 20 },
                set: { viewModel.bodyFatPct = $0 }
            ), in: 3...60, step: 0.5)
            .tint(.accentColor)

            if let bf = viewModel.bodyFatPct {
                Text(BodyFatEstimator.bodyFatCategory(gender: viewModel.gender, bodyFatPct: bf))
                    .font(.ctSubheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.ctSecondaryBg)
        .cornerRadius(14)
    }

    private var usNavyInput: some View {
        VStack(spacing: 16) {
            Text("Vücut Ölçüleri (cm)")
                .font(.ctHeadline)

            MeasurementSlider(label: "Bel Çevresi", value: $viewModel.waistCm, range: 50...150, unit: "cm")
            MeasurementSlider(label: "Boyun Çevresi", value: $viewModel.neckCm, range: 25...60, unit: "cm")

            if viewModel.gender == .female {
                MeasurementSlider(label: "Kalça Çevresi", value: $viewModel.hipCm, range: 60...160, unit: "cm")
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
            .padding(.vertical, 12)
            .background(Color.accentColor)
            .foregroundColor(.white)
            .cornerRadius(10)

            if let bf = viewModel.bodyFatPct {
                HStack {
                    Text("Tahmini Yağ Oranı:")
                        .font(.ctBody)
                    Text(String(format: "%%%.1f", bf))
                        .font(.ctMacroValue)
                        .foregroundColor(.accentColor)
                    Text("(\(BodyFatEstimator.bodyFatCategory(gender: viewModel.gender, bodyFatPct: bf)))")
                        .font(.ctFootnote)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color.ctSecondaryBg)
        .cornerRadius(14)
    }

    private var bmiResult: some View {
        VStack(spacing: 12) {
            if let bf = viewModel.bodyFatPct {
                Text("BMI Tabanlı Tahmin")
                    .font(.ctHeadline)

                Text(String(format: "%%%.1f", bf))
                    .font(.ctCalorieDisplay)
                    .foregroundColor(.accentColor)

                Text(BodyFatEstimator.bodyFatCategory(gender: viewModel.gender, bodyFatPct: bf))
                    .font(.ctSubheadline)
                    .foregroundColor(.secondary)

                Text("Bu yöntem tahminidir. Daha doğru sonuç için ölçüm yöntemini kullanabilirsiniz.")
                    .font(.ctCaption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .background(Color.ctSecondaryBg)
        .cornerRadius(14)
    }

    private var noBodyFatView: some View {
        VStack(spacing: 8) {
            Image(systemName: "info.circle")
                .font(.title2)
                .foregroundColor(.secondary)
            Text("Sorun değil! Yağ oranı olmadan da hesaplama yapabiliriz. Sadece biraz daha az hassas olacaktır.")
                .font(.ctFootnote)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color.ctSecondaryBg)
        .cornerRadius(14)
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
                    .foregroundColor(.accentColor)
            }
            Slider(value: $value, in: range, step: 1)
                .tint(.accentColor)
        }
    }
}
