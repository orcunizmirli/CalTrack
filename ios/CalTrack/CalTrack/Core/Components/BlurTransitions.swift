import SwiftUI

// MARK: - Blur Transition

struct BlurTransitionModifier: ViewModifier {
    let isActive: Bool

    func body(content: Content) -> some View {
        content
            .blur(radius: isActive ? 0 : 10)
            .opacity(isActive ? 1 : 0)
            .animation(.easeInOut(duration: 0.3), value: isActive)
    }
}

extension View {
    func blurTransition(isActive: Bool) -> some View {
        modifier(BlurTransitionModifier(isActive: isActive))
    }
}

// MARK: - Blur Fade Transition (for AnyTransition)

extension AnyTransition {
    static var blurFade: AnyTransition {
        .modifier(
            active: BlurFadeModifier(blur: 10, opacity: 0),
            identity: BlurFadeModifier(blur: 0, opacity: 1)
        )
    }
}

struct BlurFadeModifier: ViewModifier {
    let blur: CGFloat
    let opacity: Double

    func body(content: Content) -> some View {
        content
            .blur(radius: blur)
            .opacity(opacity)
    }
}

// MARK: - Sheet Blur Background

struct BlurBackgroundModifier: ViewModifier {
    let isPresented: Bool

    func body(content: Content) -> some View {
        content
            .blur(radius: isPresented ? 6 : 0)
            .animation(.easeInOut(duration: 0.25), value: isPresented)
    }
}

extension View {
    func blurOnSheet(isPresented: Bool) -> some View {
        modifier(BlurBackgroundModifier(isPresented: isPresented))
    }
}
