import SwiftUI

struct PersonalInfoView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "person.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.accentColor)

                    Text("Kişisel Bilgiler")
                        .font(.ctTitle)

                    Text("Sana en uygun kalori hedefini hesaplayabilmemiz için bilgilerine ihtiyacımız var")
                        .font(.ctSubheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)

                // Apple Health Import
                Button(action: {
                    viewModel.useHealthKit.toggle()
                    if viewModel.useHealthKit {
                        Task { await viewModel.importHealthData() }
                    }
                }) {
                    HStack {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                        Text("Apple Health'ten Al")
                            .font(.ctHeadline)
                        Spacer()
                        Image(systemName: viewModel.useHealthKit ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(viewModel.useHealthKit ? .green : .secondary)
                    }
                    .padding()
                    .background(Color.ctSecondaryBg)
                    .cornerRadius(14)
                }

                // Name
                VStack(alignment: .leading, spacing: 8) {
                    Text("İsim")
                        .font(.ctHeadline)
                    TextField("Adınız", text: $viewModel.name)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.name)
                }

                // Gender
                VStack(alignment: .leading, spacing: 8) {
                    Text("Cinsiyet")
                        .font(.ctHeadline)

                    HStack(spacing: 12) {
                        ForEach(Gender.allCases, id: \.self) { gender in
                            GenderButton(
                                title: gender.displayName,
                                icon: gender == .male ? "figure.stand" : "figure.stand.dress",
                                isSelected: viewModel.gender == gender
                            ) {
                                viewModel.gender = gender
                            }
                        }
                    }
                }

                // Birth Date
                VStack(alignment: .leading, spacing: 8) {
                    Text("Doğum Tarihi")
                        .font(.ctHeadline)

                    DatePicker(
                        "Doğum tarihi",
                        selection: $viewModel.birthDate,
                        in: ...Date(),
                        displayedComponents: .date
                    )
                    .datePickerStyle(.compact)
                    .labelsHidden()

                    Text("Yaş: \(viewModel.age)")
                        .font(.ctFootnote)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 100)
        }
    }
}

struct GenderButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title)
                Text(title)
                    .font(.ctSubheadline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(isSelected ? Color.accentColor.opacity(0.15) : Color.ctSecondaryBg)
            .foregroundColor(isSelected ? .accentColor : .primary)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
            )
        }
    }
}
