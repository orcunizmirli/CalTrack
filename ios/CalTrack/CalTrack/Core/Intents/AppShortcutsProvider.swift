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
        let goal = UserDefaultsManager.shared.dailyCalorieGoal
        // In a full implementation, this would fetch from SwiftData
        let consumed = 0 // Placeholder
        let remaining = goal - consumed

        return .result(
            dialog: "Bugün \(consumed) kalori aldın. Hedefin \(goal) kcal, \(remaining) kcal daha alabilirsin."
        )
    }
}

// MARK: - Quick Add Water Intent

struct QuickAddWaterIntent: AppIntent {
    static var title: LocalizedStringResource = "Hızlı Su Ekle"
    static var description = IntentDescription("250ml su ekle")

    func perform() async throws -> some IntentResult & ProvidesDialog {
        // Update via shared data
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
        // App will handle deep link to scan screen
        return .result()
    }
}

// MARK: - Get Macro Status Intent

struct GetMacroStatusIntent: AppIntent {
    static var title: LocalizedStringResource = "Makro Durumunu Göster"
    static var description = IntentDescription("Bugünkü protein, karbonhidrat ve yağ durumunu göster")

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let proteinGoal = UserDefaultsManager.shared.proteinGoal
        let carbsGoal = UserDefaultsManager.shared.carbsGoal
        let fatGoal = UserDefaultsManager.shared.fatGoal

        return .result(
            dialog: "Bugünkü makro hedeflerin: Protein \(proteinGoal)g, Karbonhidrat \(carbsGoal)g, Yağ \(fatGoal)g."
        )
    }
}
