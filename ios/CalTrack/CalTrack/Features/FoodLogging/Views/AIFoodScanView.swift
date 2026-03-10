import SwiftUI

struct AIFoodScanView: View {
    @StateObject private var viewModel = AIFoodScanViewModel()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationView {
            VStack {
                if viewModel.isAnalyzing {
                    analyzingView
                } else if !viewModel.editableItems.isEmpty {
                    resultView
                } else {
                    captureView
                }
            }
            .navigationTitle("AI Tarama")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") { dismiss() }
                }
            }
            .sheet(isPresented: $viewModel.showImagePicker) {
                ImagePicker(image: $viewModel.capturedImage, sourceType: viewModel.imageSourceType)
            }
            .onChange(of: viewModel.capturedImage) { _, newImage in
                if newImage != nil {
                    Task { await viewModel.analyzeFood() }
                }
            }
        }
    }

    // MARK: - Capture View
    private var captureView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "camera.viewfinder")
                .font(.system(size: 80))
                .foregroundColor(.accentColor)

            Text("Yemeğini Fotoğrafla")
                .font(.ctTitle)

            Text("Fotoğraf çek veya galeriden seç,\nAI kaloriyi hesaplasın")
                .font(.ctSubheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            // Meal type selector
            HStack(spacing: 8) {
                ForEach(MealType.allCases, id: \.self) { type in
                    Button(action: { viewModel.selectedMealType = type }) {
                        Text(type.displayName)
                            .font(.ctCaption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(viewModel.selectedMealType == type ? Color.accentColor : Color.ctSecondaryBg)
                            .foregroundColor(viewModel.selectedMealType == type ? .white : .primary)
                            .cornerRadius(20)
                    }
                }
            }

            Spacer()

            if let error = viewModel.error {
                Text(error)
                    .font(.ctFootnote)
                    .foregroundColor(.ctError)
                    .padding()
            }

            HStack(spacing: 20) {
                // Camera button
                Button(action: {
                    viewModel.imageSourceType = .camera
                    viewModel.showImagePicker = true
                }) {
                    VStack(spacing: 8) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 28))
                        Text("Kamera")
                            .font(.ctCaption)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(16)
                }

                // Gallery button
                Button(action: {
                    viewModel.imageSourceType = .photoLibrary
                    viewModel.showImagePicker = true
                }) {
                    VStack(spacing: 8) {
                        Image(systemName: "photo.fill")
                            .font(.system(size: 28))
                        Text("Galeri")
                            .font(.ctCaption)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(Color.ctSecondaryBg)
                    .foregroundColor(.primary)
                    .cornerRadius(16)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 32)
        }
    }

    // MARK: - Analyzing View
    private var analyzingView: some View {
        VStack(spacing: 24) {
            Spacer()

            if let image = viewModel.capturedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 250)
                    .cornerRadius(16)
                    .padding(.horizontal)
            }

            ProgressView()
                .scaleEffect(1.5)

            Text("Yemek analiz ediliyor...")
                .font(.ctHeadline)

            Text("AI fotoğrafı inceliyor")
                .font(.ctSubheadline)
                .foregroundColor(.secondary)

            Spacer()
        }
    }

    // MARK: - Result View
    private var resultView: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Photo preview
                if let image = viewModel.capturedImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 200)
                        .clipped()
                        .cornerRadius(16)
                        .padding(.horizontal)
                }

                // Meal description
                if let result = viewModel.analysisResult {
                    Text(result.mealDescription)
                        .font(.ctSubheadline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                }

                // Total summary
                HStack(spacing: 16) {
                    NutritionBadge(label: "Kalori", value: "\(Int(viewModel.totalCalories))", unit: "kcal", color: .ctCalories)
                    NutritionBadge(label: "Protein", value: String(format: "%.1f", viewModel.totalProtein), unit: "g", color: .ctProtein)
                    NutritionBadge(label: "Karb", value: String(format: "%.1f", viewModel.totalCarbs), unit: "g", color: .ctCarbs)
                    NutritionBadge(label: "Yağ", value: String(format: "%.1f", viewModel.totalFat), unit: "g", color: .ctFat)
                }
                .padding(.horizontal)

                // Detected Items (editable)
                VStack(spacing: 8) {
                    HStack {
                        Text("Tespit Edilen Yiyecekler")
                            .font(.ctHeadline)
                        Spacer()
                        Text("Düzenlenebilir")
                            .font(.ctCaption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)

                    ForEach(Array(viewModel.editableItems.enumerated()), id: \.element.id) { index, item in
                        DetectedFoodItemRow(
                            item: item,
                            onUpdate: { updated in
                                viewModel.updateItem(at: index, item: updated)
                            },
                            onDelete: {
                                viewModel.removeItem(at: index)
                            }
                        )
                    }
                }

                // Action buttons
                VStack(spacing: 12) {
                    // Save button
                    Button(action: saveMeals) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Kaydet")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(14)
                        .fontWeight(.semibold)
                    }

                    // Retake button
                    Button(action: {
                        viewModel.editableItems = []
                        viewModel.analysisResult = nil
                        viewModel.capturedImage = nil
                    }) {
                        Text("Tekrar Çek")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .foregroundColor(.accentColor)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
            .padding(.top, 8)
        }
    }

    private func saveMeals() {
        for item in viewModel.editableItems {
            let entry = MealEntry(
                foodName: item.name,
                mealType: viewModel.selectedMealType,
                quantityG: item.portionG,
                calories: item.calories,
                proteinG: item.proteinG,
                carbsG: item.carbsG,
                fatG: item.fatG,
                isAIScan: true
            )
            modelContext.insert(entry)
        }
        dismiss()
    }
}

struct NutritionBadge: View {
    let label: String
    let value: String
    let unit: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.ctHeadline)
                .foregroundColor(color)
            Text(unit)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
            Text(label)
                .font(.ctCaption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(color.opacity(0.1))
        .cornerRadius(10)
    }
}

struct DetectedFoodItemRow: View {
    let item: AIDetectedFoodItem
    let onUpdate: (AIDetectedFoodItem) -> Void
    let onDelete: () -> Void

    @State private var isEditing = false
    @State private var editPortionG: Double

    init(item: AIDetectedFoodItem, onUpdate: @escaping (AIDetectedFoodItem) -> Void, onDelete: @escaping () -> Void) {
        self.item = item
        self.onUpdate = onUpdate
        self.onDelete = onDelete
        self._editPortionG = State(initialValue: item.portionG)
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name)
                        .font(.ctHeadline)
                    if let nameEn = item.nameEn {
                        Text(nameEn)
                            .font(.ctCaption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // Confidence
                Text("\(Int(item.confidence * 100))%")
                    .font(.ctCaption)
                    .foregroundColor(item.confidence > 0.8 ? .ctSuccess : .ctWarning)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background((item.confidence > 0.8 ? Color.ctSuccess : Color.ctWarning).opacity(0.15))
                    .cornerRadius(6)

                Button(action: { withAnimation { isEditing.toggle() } }) {
                    Image(systemName: "pencil.circle")
                        .foregroundColor(.accentColor)
                }

                Button(action: onDelete) {
                    Image(systemName: "xmark.circle")
                        .foregroundColor(.ctError)
                }
            }

            HStack(spacing: 12) {
                Text("\(Int(item.portionG))g")
                    .font(.ctSubheadline)
                    .foregroundColor(.secondary)

                Spacer()

                Text("\(Int(item.calories)) kcal")
                    .font(.ctSubheadline)
                    .fontWeight(.medium)

                HStack(spacing: 6) {
                    Text("P:\(Int(item.proteinG))g").foregroundColor(.ctProtein)
                    Text("K:\(Int(item.carbsG))g").foregroundColor(.ctCarbs)
                    Text("Y:\(Int(item.fatG))g").foregroundColor(.ctFat)
                }
                .font(.system(size: 11))
            }

            if isEditing {
                VStack(spacing: 8) {
                    HStack {
                        Text("Porsiyon")
                            .font(.ctSubheadline)
                        Spacer()
                        Text("\(Int(editPortionG))g")
                            .font(.ctHeadline)
                    }

                    Slider(value: $editPortionG, in: 10...1000, step: 10)
                        .tint(.accentColor)
                        .onChange(of: editPortionG) { _, newValue in
                            let ratio = newValue / item.portionG
                            var updated = item
                            updated.portionG = newValue
                            updated.calories = item.calories * ratio
                            updated.proteinG = item.proteinG * ratio
                            updated.carbsG = item.carbsG * ratio
                            updated.fatG = item.fatG * ratio
                            onUpdate(updated)
                        }
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(Color.ctSecondaryBg)
        .cornerRadius(14)
        .padding(.horizontal)
    }
}
