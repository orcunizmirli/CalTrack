import Foundation
import SwiftUI

@MainActor
class AIFoodScanViewModel: ObservableObject {
    @Published var capturedImage: UIImage?
    @Published var analysisResult: AIFoodAnalysisResponse?
    @Published var editableItems: [AIDetectedFoodItem] = []
    @Published var isAnalyzing = false
    @Published var error: String?
    @Published var selectedMealType: MealType = .lunch
    @Published var showImagePicker = false
    @Published var showCamera = false
    @Published var imageSourceType: UIImagePickerController.SourceType = .camera

    func analyzeFood() async {
        guard let image = capturedImage else { return }
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            error = "Fotoğraf işlenemedi"
            return
        }

        isAnalyzing = true
        error = nil

        do {
            let result: AIFoodAnalysisResponse = try await APIClient.shared.upload(
                endpoint: APIEndpoints.aiAnalyzeFood,
                imageData: imageData,
                additionalFields: ["meal_type": selectedMealType.rawValue]
            )
            analysisResult = result
            editableItems = result.items
        } catch {
            self.error = "Analiz başarısız: \(error.localizedDescription)"
            // Provide mock data for development
            #if DEBUG
            provideMockResult()
            #endif
        }

        isAnalyzing = false
    }

    func updateItem(at index: Int, item: AIDetectedFoodItem) {
        guard index < editableItems.count else { return }
        editableItems[index] = item
    }

    func removeItem(at index: Int) {
        guard index < editableItems.count else { return }
        editableItems.remove(at: index)
    }

    func addItem(_ item: AIDetectedFoodItem) {
        editableItems.append(item)
    }

    var totalCalories: Double {
        editableItems.reduce(0) { $0 + $1.calories }
    }

    var totalProtein: Double {
        editableItems.reduce(0) { $0 + $1.proteinG }
    }

    var totalCarbs: Double {
        editableItems.reduce(0) { $0 + $1.carbsG }
    }

    var totalFat: Double {
        editableItems.reduce(0) { $0 + $1.fatG }
    }

    #if DEBUG
    private func provideMockResult() {
        let mockItems = [
            AIDetectedFoodItem(
                name: "Izgara Tavuk Göğsü",
                nameEn: "Grilled Chicken Breast",
                portionG: 150,
                calories: 248,
                proteinG: 46.5,
                carbsG: 0,
                fatG: 5.4,
                confidence: 0.92
            ),
            AIDetectedFoodItem(
                name: "Pilav",
                nameEn: "Rice",
                portionG: 200,
                calories: 260,
                proteinG: 5.4,
                carbsG: 56,
                fatG: 0.6,
                confidence: 0.88
            ),
            AIDetectedFoodItem(
                name: "Yeşil Salata",
                nameEn: "Green Salad",
                portionG: 100,
                calories: 20,
                proteinG: 1.5,
                carbsG: 3.5,
                fatG: 0.2,
                confidence: 0.85
            )
        ]

        let mockResponse = AIFoodAnalysisResponse(
            items: mockItems,
            totalCalories: mockItems.reduce(0) { $0 + $1.calories },
            mealDescription: "Izgara tavuk göğsü, pilav ve yeşil salata",
            confidence: 0.88
        )

        analysisResult = mockResponse
        editableItems = mockItems
    }
    #endif
}
