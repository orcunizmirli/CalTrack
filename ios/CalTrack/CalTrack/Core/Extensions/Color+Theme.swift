import SwiftUI

extension Color {
    // MARK: - Backgrounds (Dark-First)
    static let ctBackground = Color(red: 0, green: 0, blue: 0)
    static let ctSurface = Color(red: 0.04, green: 0.04, blue: 0.04)
    static let ctSurfaceElevated = Color(red: 0.08, green: 0.08, blue: 0.08)

    // MARK: - Accent (Cal.AI Green)
    static let ctAccent = Color(red: 0.29, green: 0.87, blue: 0.50)
    static let ctAccentDim = Color(red: 0.13, green: 0.77, blue: 0.37)

    // MARK: - Macro Colors
    static let ctProtein = Color(red: 0.376, green: 0.647, blue: 0.98)
    static let ctCarbs = Color(red: 0.984, green: 0.573, blue: 0.235)
    static let ctFat = Color(red: 0.973, green: 0.443, blue: 0.443)
    static let ctCalories = Color(red: 0.29, green: 0.87, blue: 0.50)

    // MARK: - Semantic Colors
    static let ctSuccess = Color(red: 0.29, green: 0.87, blue: 0.50)
    static let ctWarning = Color(red: 0.984, green: 0.749, blue: 0.141)
    static let ctError = Color(red: 0.937, green: 0.267, blue: 0.267)

    // MARK: - Text
    static let ctTextPrimary = Color.white
    static let ctTextSecondary = Color(red: 0.612, green: 0.639, blue: 0.686)
    static let ctTextTertiary = Color(red: 0.420, green: 0.451, blue: 0.502)

    // MARK: - Meal Type Colors
    static let ctBreakfast = Color(red: 1.0, green: 0.75, blue: 0.30)
    static let ctLunch = Color(red: 0.40, green: 0.75, blue: 0.95)
    static let ctDinner = Color(red: 0.65, green: 0.45, blue: 0.90)
    static let ctSnack = Color(red: 0.90, green: 0.55, blue: 0.65)

    // MARK: - Legacy Compatibility
    static let ctPrimary = ctAccent
    static let ctSecondaryBg = ctSurfaceElevated
    static let ctTertiaryBg = ctSurface
}

// MARK: - ShapeStyle forwarding (iOS 26+)
extension ShapeStyle where Self == Color {
    static var ctAccent: Color { Color.ctAccent }
    static var ctAccentDim: Color { Color.ctAccentDim }
    static var ctProtein: Color { Color.ctProtein }
    static var ctCarbs: Color { Color.ctCarbs }
    static var ctFat: Color { Color.ctFat }
    static var ctCalories: Color { Color.ctCalories }
    static var ctSuccess: Color { Color.ctSuccess }
    static var ctWarning: Color { Color.ctWarning }
    static var ctError: Color { Color.ctError }
    static var ctTextPrimary: Color { Color.ctTextPrimary }
    static var ctTextSecondary: Color { Color.ctTextSecondary }
    static var ctTextTertiary: Color { Color.ctTextTertiary }
    static var ctBreakfast: Color { Color.ctBreakfast }
    static var ctLunch: Color { Color.ctLunch }
    static var ctDinner: Color { Color.ctDinner }
    static var ctSnack: Color { Color.ctSnack }
    static var ctBackground: Color { Color.ctBackground }
    static var ctSurface: Color { Color.ctSurface }
    static var ctSurfaceElevated: Color { Color.ctSurfaceElevated }
}

extension Font {
    static let ctHero = Font.system(size: 56, weight: .bold, design: .rounded)
    static let ctLargeTitle = Font.system(size: 34, weight: .bold, design: .rounded)
    static let ctTitle = Font.system(size: 24, weight: .bold, design: .rounded)
    static let ctTitle2 = Font.system(size: 20, weight: .semibold, design: .rounded)
    static let ctHeadline = Font.system(size: 17, weight: .semibold)
    static let ctBody = Font.system(size: 17, weight: .regular)
    static let ctCallout = Font.system(size: 16, weight: .regular)
    static let ctSubheadline = Font.system(size: 15, weight: .regular)
    static let ctFootnote = Font.system(size: 13, weight: .regular)
    static let ctCaption = Font.system(size: 12, weight: .regular)
    static let ctCalorieDisplay = Font.system(size: 48, weight: .bold, design: .rounded)
    static let ctMacroValue = Font.system(size: 20, weight: .bold, design: .rounded)
}
