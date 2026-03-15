import SwiftUI

// MARK: - Glass Card Modifiers

struct GlassCardModifier: ViewModifier {
    var padding: CGFloat = 16
    var cornerRadius: CGFloat = 16

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

struct GlassClearCardModifier: ViewModifier {
    var padding: CGFloat = 10
    var cornerRadius: CGFloat = 12

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .glassEffect(.clear, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

extension View {
    func glassCard(padding: CGFloat = 16, cornerRadius: CGFloat = 16) -> some View {
        modifier(GlassCardModifier(padding: padding, cornerRadius: cornerRadius))
    }

    func glassClearCard(padding: CGFloat = 10, cornerRadius: CGFloat = 12) -> some View {
        modifier(GlassClearCardModifier(padding: padding, cornerRadius: cornerRadius))
    }
}

// MARK: - Button Styles

struct CTPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.ctAccent)
            .foregroundStyle(.black)
            .font(.ctHeadline)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .opacity(configuration.isPressed ? 0.85 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.spring(response: 0.2), value: configuration.isPressed)
    }
}

struct CTGhostButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(Color.ctAccent)
            .font(.ctSubheadline)
            .opacity(configuration.isPressed ? 0.6 : 1)
    }
}

extension ButtonStyle where Self == CTPrimaryButtonStyle {
    static var ctPrimary: CTPrimaryButtonStyle { CTPrimaryButtonStyle() }
}

extension ButtonStyle where Self == CTGhostButtonStyle {
    static var ctGhost: CTGhostButtonStyle { CTGhostButtonStyle() }
}

// MARK: - Animation Presets

extension Animation {
    static let ctSpring = Animation.spring(response: 0.35, dampingFraction: 0.8)
    static let ctQuick = Animation.easeInOut(duration: 0.2)
    static let ctMedium = Animation.easeInOut(duration: 0.3)
    static let ctRing = Animation.easeInOut(duration: 0.8)
}

// MARK: - Haptics

enum HapticManager {
    static func light() { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
    static func medium() { UIImpactFeedbackGenerator(style: .medium).impactOccurred() }
    static func success() { UINotificationFeedbackGenerator().notificationOccurred(.success) }
    static func selection() { UISelectionFeedbackGenerator().selectionChanged() }
}
