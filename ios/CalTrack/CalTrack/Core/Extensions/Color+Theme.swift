import SwiftUI

extension Color {
    // MARK: - Brand Colors
    static let ctPrimary = Color("AccentColor")
    static let ctBackground = Color(uiColor: .systemBackground)
    static let ctSecondaryBg = Color(uiColor: .secondarySystemBackground)
    static let ctTertiaryBg = Color(uiColor: .tertiarySystemBackground)

    // MARK: - Macro Colors
    static let ctProtein = Color(red: 0.35, green: 0.65, blue: 0.95)    // Blue
    static let ctCarbs = Color(red: 0.95, green: 0.70, blue: 0.25)      // Orange
    static let ctFat = Color(red: 0.90, green: 0.35, blue: 0.40)        // Red
    static let ctCalories = Color(red: 0.40, green: 0.85, blue: 0.55)   // Green

    // MARK: - Semantic Colors
    static let ctSuccess = Color(red: 0.30, green: 0.80, blue: 0.45)
    static let ctWarning = Color(red: 0.95, green: 0.75, blue: 0.25)
    static let ctError = Color(red: 0.90, green: 0.30, blue: 0.30)

    // MARK: - Meal Type Colors
    static let ctBreakfast = Color(red: 1.0, green: 0.75, blue: 0.30)
    static let ctLunch = Color(red: 0.40, green: 0.75, blue: 0.95)
    static let ctDinner = Color(red: 0.65, green: 0.45, blue: 0.90)
    static let ctSnack = Color(red: 0.90, green: 0.55, blue: 0.65)
}

extension Font {
    static let ctLargeTitle = Font.system(size: 34, weight: .bold, design: .rounded)
    static let ctTitle = Font.system(size: 24, weight: .bold, design: .rounded)
    static let ctTitle2 = Font.system(size: 20, weight: .semibold, design: .rounded)
    static let ctHeadline = Font.system(size: 17, weight: .semibold)
    static let ctBody = Font.system(size: 17, weight: .regular)
    static let ctCallout = Font.system(size: 16, weight: .regular)
    static let ctSubheadline = Font.system(size: 15, weight: .regular)
    static let ctFootnote = Font.system(size: 13, weight: .regular)
    static let ctCaption = Font.system(size: 12, weight: .regular)

    // Numeric display
    static let ctCalorieDisplay = Font.system(size: 48, weight: .bold, design: .rounded)
    static let ctMacroValue = Font.system(size: 20, weight: .bold, design: .rounded)
}
