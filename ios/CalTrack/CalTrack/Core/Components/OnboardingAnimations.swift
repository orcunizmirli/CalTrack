import SwiftUI

// MARK: - Staggered Fade-In Slide-Up Modifier

struct StaggeredAppearModifier: ViewModifier {
    let delay: Double
    @State private var isVisible = false

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 20)
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.75).delay(delay)) {
                    isVisible = true
                }
            }
    }
}

extension View {
    func staggeredAppear(delay: Double = 0) -> some View {
        modifier(StaggeredAppearModifier(delay: delay))
    }
}

// MARK: - Bounce-In Modifier

struct BounceInModifier: ViewModifier {
    let delay: Double
    @State private var isVisible = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isVisible ? 1 : 0.3)
            .opacity(isVisible ? 1 : 0)
            .onAppear {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.5).delay(delay)) {
                    isVisible = true
                }
            }
    }
}

extension View {
    func bounceIn(delay: Double = 0) -> some View {
        modifier(BounceInModifier(delay: delay))
    }
}

// MARK: - Pulse/Scale Animation for Icons

struct PulseModifier: ViewModifier {
    @State private var isPulsing = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? 1.1 : 1.0)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                    isPulsing = true
                }
            }
    }
}

extension View {
    func pulse() -> some View {
        modifier(PulseModifier())
    }
}

// MARK: - Animated Progress Bar for Onboarding

struct AnimatedOnboardingProgress: View {
    let current: Int
    let total: Int

    private var progress: Double {
        Double(current + 1) / Double(total)
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Background track
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(Color.ctSurfaceElevated)
                    .frame(height: 6)

                // Animated gradient fill
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [.ctAccent, .ctAccentDim, .ctAccent],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geo.size.width * progress, height: 6)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: current)
            }
        }
        .frame(height: 6)
    }
}

// MARK: - Step Icon with Animation

struct OnboardingStepIcon: View {
    let systemName: String
    let isActive: Bool

    @State private var scale: CGFloat = 0.5

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: 64))
            .foregroundStyle(.ctAccent)
            .scaleEffect(scale)
            .onChange(of: isActive) { _, active in
                if active {
                    scale = 0.5
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) {
                        scale = 1.0
                    }
                }
            }
            .onAppear {
                if isActive {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) {
                        scale = 1.0
                    }
                }
            }
    }
}
