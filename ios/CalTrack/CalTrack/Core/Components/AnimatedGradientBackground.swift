import SwiftUI

// MARK: - Animated Mesh Gradient Background

struct AnimatedGradientBackground: View {
    var colors: [Color] = [.ctAccent, .ctAccentDim, Color(red: 0.1, green: 0.3, blue: 0.2)]
    var opacity: Double = 0.15

    @State private var animateGradient = false

    var body: some View {
        MeshGradient(
            width: 3, height: 3,
            points: animateGradient ? animatedPoints : initialPoints,
            colors: [
                colors[0].opacity(opacity),
                colors[1].opacity(opacity * 0.8),
                colors[2].opacity(opacity * 0.6),
                colors[1].opacity(opacity * 0.7),
                colors[0].opacity(opacity * 0.5),
                colors[2].opacity(opacity * 0.8),
                colors[2].opacity(opacity * 0.6),
                colors[0].opacity(opacity * 0.7),
                colors[1].opacity(opacity * 0.5)
            ]
        )
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 6).repeatForever(autoreverses: true)) {
                animateGradient = true
            }
        }
    }

    private var initialPoints: [SIMD2<Float>] {
        [
            SIMD2(0.0, 0.0), SIMD2(0.5, 0.0), SIMD2(1.0, 0.0),
            SIMD2(0.0, 0.5), SIMD2(0.5, 0.5), SIMD2(1.0, 0.5),
            SIMD2(0.0, 1.0), SIMD2(0.5, 1.0), SIMD2(1.0, 1.0)
        ]
    }

    private var animatedPoints: [SIMD2<Float>] {
        [
            SIMD2(0.0, 0.0), SIMD2(0.6, 0.05), SIMD2(1.0, 0.0),
            SIMD2(0.05, 0.55), SIMD2(0.45, 0.45), SIMD2(0.95, 0.55),
            SIMD2(0.0, 1.0), SIMD2(0.4, 0.95), SIMD2(1.0, 1.0)
        ]
    }
}

// MARK: - Onboarding Step Gradient

struct OnboardingStepGradient: View {
    let step: Int

    private var stepColors: [Color] {
        switch step {
        case 0: return [.ctAccent, .ctAccentDim, Color(red: 0.1, green: 0.4, blue: 0.3)]
        case 1: return [.ctProtein, .ctAccent, Color(red: 0.15, green: 0.3, blue: 0.5)]
        case 2: return [.ctCarbs, .ctAccent, Color(red: 0.3, green: 0.2, blue: 0.1)]
        case 3: return [.ctAccent, .ctWarning, Color(red: 0.2, green: 0.3, blue: 0.1)]
        case 4: return [.ctProtein, .ctCarbs, Color(red: 0.1, green: 0.2, blue: 0.4)]
        case 5: return [.ctFat, .ctProtein, Color(red: 0.3, green: 0.1, blue: 0.2)]
        default: return [.ctSuccess, .ctAccent, Color(red: 0.1, green: 0.4, blue: 0.2)]
        }
    }

    var body: some View {
        AnimatedGradientBackground(colors: stepColors, opacity: 0.1)
            .animation(.easeInOut(duration: 0.8), value: step)
    }
}

// MARK: - Celebration Gradient

struct CelebrationGradient: View {
    @State private var animate = false

    var body: some View {
        AnimatedGradientBackground(
            colors: [.ctSuccess, .ctAccent, .ctWarning],
            opacity: 0.2
        )
    }
}

// MARK: - View Extension

extension View {
    func animatedGradientBackground(
        colors: [Color] = [.ctAccent, .ctAccentDim, Color(red: 0.1, green: 0.3, blue: 0.2)],
        opacity: Double = 0.15
    ) -> some View {
        self.background(AnimatedGradientBackground(colors: colors, opacity: opacity))
    }
}
