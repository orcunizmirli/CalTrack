import AppIntents

struct ForkcastShortcutsProvider: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: GetCalorieStatusIntent(),
            phrases: [
                "Bugün kaç kalori aldım \(.applicationName)?",
                "\(.applicationName) kalori durumu",
                "Kalorilerim \(.applicationName)"
            ],
            shortTitle: "Kalori Durumu",
            systemImageName: "flame.fill"
        )

        AppShortcut(
            intent: QuickAddWaterIntent(),
            phrases: [
                "Su ekle \(.applicationName)",
                "\(.applicationName) su ekle",
                "Bir bardak su ekle \(.applicationName)"
            ],
            shortTitle: "Su Ekle",
            systemImageName: "drop.fill"
        )

        AppShortcut(
            intent: OpenFoodScanIntent(),
            phrases: [
                "Yemek tara \(.applicationName)",
                "\(.applicationName) yemek tara",
                "\(.applicationName) ile fotoğraf çek"
            ],
            shortTitle: "Yemek Tara",
            systemImageName: "camera.fill"
        )

        AppShortcut(
            intent: GetMacroStatusIntent(),
            phrases: [
                "Makrolarım \(.applicationName)",
                "\(.applicationName) bugünkü makrolarım",
                "Protein durumum \(.applicationName)"
            ],
            shortTitle: "Makro Durumu",
            systemImageName: "chart.bar.fill"
        )
    }
}

// MARK: - Get Calorie Status Intent

struct GetCalorieStatusIntent: AppIntent {
    static var title: LocalizedStringResource = "Kalori Durumunu Göster"
    static var description = IntentDescription("Bugünkü kalori durumunu göster")

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let data = WidgetDataManager.load()
        let consumed = Int(data.caloriesConsumed)
        let goal = data.calorieGoal
        let burned = Int(data.caloriesBurned)
        let remaining = max(0, goal - consumed + burned)

        return .result(
            dialog: "Bugün \(consumed) kalori aldın, \(burned) kcal yaktın. Hedefin \(goal) kcal, \(remaining) kcal daha alabilirsin."
        )
    }
}

// MARK: - Quick Add Water Intent

struct QuickAddWaterIntent: AppIntent {
    static var title: LocalizedStringResource = "Hızlı Su Ekle"
    static var description = IntentDescription("250ml su ekle")

    func perform() async throws -> some IntentResult & ProvidesDialog {
        var data = WidgetDataManager.load()
        data.waterMl += 250
        data.lastUpdated = Date()
        WidgetDataManager.save(data)

        return .result(
            dialog: "250ml su eklendi. Bugün toplam \(data.waterMl) ml içtin."
        )
    }
}

// MARK: - Open Food Scan Intent

struct OpenFoodScanIntent: AppIntent {
    static var title: LocalizedStringResource = "Yemek Tara"
    static var description = IntentDescription("AI ile yemek tarama ekranını aç")
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        return .result()
    }
}

// MARK: - Get Macro Status Intent

struct GetMacroStatusIntent: AppIntent {
    static var title: LocalizedStringResource = "Makro Durumunu Göster"
    static var description = IntentDescription("Bugünkü protein, karbonhidrat ve yağ durumunu göster")

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let data = WidgetDataManager.load()
        let protein = Int(data.proteinG)
        let carbs = Int(data.carbsG)
        let fat = Int(data.fatG)

        return .result(
            dialog: "Bugün \(protein)g protein (hedef \(data.proteinGoal)g), \(carbs)g karbonhidrat (hedef \(data.carbsGoal)g), \(fat)g yağ (hedef \(data.fatGoal)g) aldın."
        )
    }
}
