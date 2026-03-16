import SwiftUI

struct AppLogoView: View {
    var size: CGFloat = 120
    @State private var isPulsing = false
    @State private var glowOpacity: Double = 0.3

    var body: some View {
        ZStack {
            // Outer glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.ctAccent.opacity(glowOpacity), .clear],
                        center: .center,
                        startRadius: size * 0.3,
                        endRadius: size * 0.7
                    )
                )
                .frame(width: size * 1.4, height: size * 1.4)

            // Gradient circle background
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.ctAccent, Color.ctAccentDim],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)
                .shadow(color: .ctAccent.opacity(0.4), radius: 20)

            // Fork + Knife icon
            Image(systemName: "fork.knife")
                .font(.system(size: size * 0.4, weight: .semibold))
                .foregroundStyle(.black)
                .scaleEffect(isPulsing ? 1.05 : 1.0)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                isPulsing = true
                glowOpacity = 0.6
            }
        }
    }
}

// MARK: - Floating Food Particles

struct FloatingFoodParticlesView: View {
    let emojis = ["🍎", "🥑", "🍗", "🥦", "🍳", "🥗", "🍕", "🥩", "🫐", "🍌", "🥕", "🍚"]
    @State private var particles: [FoodParticle] = []

    struct FoodParticle: Identifiable {
        let id = UUID()
        let emoji: String
        var x: CGFloat
        var y: CGFloat
        var opacity: Double
        var scale: CGFloat
        var speed: Double
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(particles) { particle in
                    Text(particle.emoji)
                        .font(.system(size: 24))
                        .opacity(particle.opacity)
                        .scaleEffect(particle.scale)
                        .position(x: particle.x, y: particle.y)
                }
            }
            .onAppear {
                generateParticles(in: geo.size)
                animateParticles(in: geo.size)
            }
        }
        .allowsHitTesting(false)
    }

    private func generateParticles(in size: CGSize) {
        particles = (0..<8).map { _ in
            FoodParticle(
                emoji: emojis.randomElement()!,
                x: CGFloat.random(in: 20...(size.width - 20)),
                y: CGFloat.random(in: 20...(size.height - 20)),
                opacity: Double.random(in: 0.1...0.25),
                scale: CGFloat.random(in: 0.6...1.0),
                speed: Double.random(in: 3...6)
            )
        }
    }

    private func animateParticles(in size: CGSize) {
        for i in particles.indices {
            let duration = particles[i].speed
            withAnimation(.easeInOut(duration: duration).repeatForever(autoreverses: true)) {
                particles[i].y += CGFloat.random(in: -30...30)
                particles[i].opacity = Double.random(in: 0.08...0.2)
            }
        }
    }
}

// MARK: - Animated Feature Row

struct AnimatedFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    let index: Int
    @State private var isVisible = false

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.ctAccent)
                .frame(width: 44, height: 44)
                .background(Color.ctAccent.opacity(0.1))
                .cornerRadius(12)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.ctHeadline)
                Text(description)
                    .font(.ctFootnote)
                    .foregroundStyle(.ctTextSecondary)
            }
        }
        .opacity(isVisible ? 1 : 0)
        .offset(x: isVisible ? 0 : -30)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(Double(index) * 0.15)) {
                isVisible = true
            }
        }
    }
}
