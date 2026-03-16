import SwiftUI

struct ConfettiView: View {
    @State private var particles: [ConfettiParticle] = []
    @State private var isActive = false

    let colors: [Color] = [.ctAccent, .ctProtein, .ctCarbs, .ctFat, .ctWarning, .ctSuccess]

    struct ConfettiParticle: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        let color: Color
        let size: CGFloat
        let rotation: Double
        let speed: Double
        let wobble: CGFloat
        let shape: Int // 0=circle, 1=rect, 2=triangle
    }

    var body: some View {
        GeometryReader { geo in
            Canvas { context, size in
                for particle in particles {
                    let rect = CGRect(
                        x: particle.x - particle.size / 2,
                        y: particle.y - particle.size / 2,
                        width: particle.size,
                        height: particle.size
                    )

                    context.opacity = max(0, 1.0 - particle.y / size.height)

                    switch particle.shape {
                    case 0:
                        context.fill(Circle().path(in: rect), with: .color(particle.color))
                    case 1:
                        context.fill(
                            RoundedRectangle(cornerRadius: 2).path(in: rect),
                            with: .color(particle.color)
                        )
                    default:
                        var path = Path()
                        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
                        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
                        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
                        path.closeSubpath()
                        context.fill(path, with: .color(particle.color))
                    }
                }
            }
            .onAppear {
                startConfetti(in: geo.size)
            }
        }
        .allowsHitTesting(false)
    }

    private func startConfetti(in size: CGSize) {
        // Generate particles
        particles = (0..<50).map { _ in
            ConfettiParticle(
                x: CGFloat.random(in: 0...size.width),
                y: CGFloat.random(in: -size.height...0),
                color: colors.randomElement()!,
                size: CGFloat.random(in: 4...10),
                rotation: Double.random(in: 0...360),
                speed: Double.random(in: 2...5),
                wobble: CGFloat.random(in: -2...2),
                shape: Int.random(in: 0...2)
            )
        }

        // Animate particles falling
        Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { timer in
            var allOffScreen = true
            for i in particles.indices {
                particles[i].y += CGFloat(particles[i].speed)
                particles[i].x += particles[i].wobble * sin(CGFloat(particles[i].y / 30))
                if particles[i].y < size.height + 20 {
                    allOffScreen = false
                }
            }
            if allOffScreen {
                timer.invalidate()
                particles = []
            }
        }
    }
}

// MARK: - Mini Celebration (for water goal, etc.)

struct MiniCelebrationView: View {
    @State private var scale: CGFloat = 0.3
    @State private var opacity: Double = 1.0
    @State private var ringScale: CGFloat = 0.5

    let color: Color
    let icon: String

    var body: some View {
        ZStack {
            // Expanding ring
            Circle()
                .stroke(color.opacity(opacity * 0.5), lineWidth: 3)
                .frame(width: 60, height: 60)
                .scaleEffect(ringScale)

            // Icon
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundStyle(color)
                .scaleEffect(scale)
        }
        .onAppear {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.4)) {
                scale = 1.2
            }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6).delay(0.1)) {
                scale = 1.0
            }
            withAnimation(.easeOut(duration: 0.8)) {
                ringScale = 2.0
                opacity = 0
            }
        }
    }
}

// MARK: - Goal Reached Overlay

struct GoalReachedOverlay: View {
    let title: String
    let subtitle: String
    @Binding var isShowing: Bool

    var body: some View {
        if isShowing {
            ZStack {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()

                VStack(spacing: 20) {
                    ConfettiView()
                        .frame(height: 200)

                    Image(systemName: "trophy.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(.ctWarning)

                    Text(title)
                        .font(.ctTitle)
                        .multilineTextAlignment(.center)

                    Text(subtitle)
                        .font(.ctSubheadline)
                        .foregroundStyle(.ctTextSecondary)
                        .multilineTextAlignment(.center)

                    Button("Harika!") {
                        withAnimation { isShowing = false }
                    }
                    .buttonStyle(.ctPrimary)
                    .padding(.horizontal, 40)
                    .padding(.top, 8)
                }
                .padding()
            }
            .transition(.opacity)
        }
    }
}

// MARK: - Streak Milestone View

struct StreakMilestoneView: View {
    let days: Int
    @State private var showConfetti = false

    private var milestoneEmoji: String {
        switch days {
        case 7: return "🔥"
        case 30: return "⭐"
        case 100: return "🏆"
        case 365: return "💎"
        default: return "🎉"
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            Text(milestoneEmoji)
                .font(.system(size: 56))
                .bounceIn()

            Text("\(days) Gün Serisi!")
                .font(.ctTitle)
                .staggeredAppear(delay: 0.2)

            Text("Harika gidiyorsun, devam et!")
                .font(.ctSubheadline)
                .foregroundStyle(.ctTextSecondary)
                .staggeredAppear(delay: 0.4)
        }
        .overlay {
            if showConfetti {
                ConfettiView()
            }
        }
        .onAppear {
            HapticManager.success()
            showConfetti = true
        }
    }
}
