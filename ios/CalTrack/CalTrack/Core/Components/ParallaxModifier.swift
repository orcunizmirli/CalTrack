import SwiftUI

// MARK: - Parallax Header Modifier

struct ParallaxHeaderModifier: ViewModifier {
    let coordinateSpace: String
    var maxOffset: CGFloat = 100

    func body(content: Content) -> some View {
        GeometryReader { geo in
            let minY = geo.frame(in: .named(coordinateSpace)).minY
            let scrollOffset = max(0, -minY)
            let progress = min(scrollOffset / maxOffset, 1.0)

            content
                .scaleEffect(1.0 - progress * 0.15)
                .opacity(1.0 - progress * 0.5)
                .offset(y: scrollOffset * 0.3)
        }
    }
}

// MARK: - Depth Parallax for Cards

struct DepthParallaxModifier: ViewModifier {
    let coordinateSpace: String
    let intensity: CGFloat

    func body(content: Content) -> some View {
        GeometryReader { geo in
            let frame = geo.frame(in: .named(coordinateSpace))
            let containerHeight = geo.frame(in: .global).height
            let screenHeight = max(containerHeight, 1)
            let centerY = frame.midY / screenHeight
            let offset = (centerY - 0.5) * intensity

            content
                .offset(y: offset)
        }
    }
}

extension View {
    func parallaxHeader(in coordinateSpace: String, maxOffset: CGFloat = 100) -> some View {
        modifier(ParallaxHeaderModifier(coordinateSpace: coordinateSpace, maxOffset: maxOffset))
    }

    func depthParallax(in coordinateSpace: String, intensity: CGFloat = 20) -> some View {
        modifier(DepthParallaxModifier(coordinateSpace: coordinateSpace, intensity: intensity))
    }
}
