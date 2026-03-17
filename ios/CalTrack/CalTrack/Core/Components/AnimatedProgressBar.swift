import SwiftUI

// MARK: - Gradient Glow Ring (for CalorieRing)

struct GradientGlowRing: View {
    let progress: Double
    let lineWidth: CGFloat
    let size: CGFloat
    let isOverGoal: Bool

    @State private var glowPhase: CGFloat = 0

    private var ringColor: Color {
        isOverGoal ? .ctError : .ctAccent
    }

    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(ringColor.opacity(0.1), lineWidth: lineWidth)
                .frame(width: size, height: size)

            // Progress ring with gradient
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: isOverGoal
                            ? [.ctError, .ctError.opacity(0.6), .ctError]
                            : [.ctAccent, .ctAccentDim, .ctAccent]
                        ),
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(-90 + 360 * progress)
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
                .animation(.ctRing, value: progress)

            // Glow trail at the tip
            if progress > 0.02 {
                Circle()
                    .fill(ringColor)
                    .frame(width: lineWidth * 1.3, height: lineWidth * 1.3)
                    .shadow(color: ringColor.opacity(0.6), radius: 8)
                    .offset(y: -size / 2)
                    .rotationEffect(.degrees(360 * progress - 90))
                    .animation(.ctRing, value: progress)
            }
        }
    }
}

// MARK: - Wave Fill Progress (for MacroProgress)

struct WaveFillCircle: View {
    let progress: Double
    let color: Color
    let size: CGFloat

    @State private var waveOffset: CGFloat = 0

    var body: some View {
        ZStack {
            // Background
            Circle()
                .stroke(color.opacity(0.2), lineWidth: 3)
                .frame(width: size, height: size)

            // Wave fill
            Circle()
                .fill(color.opacity(0.15))
                .frame(width: size, height: size)
                .overlay(
                    WaveShape(offset: waveOffset, progress: progress)
                        .fill(color.opacity(0.3))
                )
                .clipShape(Circle())

            // Progress ring
            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: progress)
        }
        .onAppear {
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                waveOffset = .pi * 2
            }
        }
    }
}

struct WaveShape: Shape {
    var offset: CGFloat
    var progress: Double

    var animatableData: AnimatablePair<CGFloat, Double> {
        get { AnimatablePair(offset, progress) }
        set {
            offset = newValue.first
            progress = newValue.second
        }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let waterLevel = rect.height * (1 - progress)
        let waveHeight: CGFloat = 4

        path.move(to: CGPoint(x: 0, y: waterLevel))

        let step = max(2, rect.width / 30) // ~30 points instead of per-pixel
        for x in stride(from: CGFloat(0), through: rect.width, by: step) {
            let relativeX = x / rect.width
            let sine = sin(relativeX * .pi * 2 + offset)
            let y = waterLevel + sine * waveHeight
            path.addLine(to: CGPoint(x: x, y: y))
        }

        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.closeSubpath()

        return path
    }
}

// MARK: - Liquid Water Progress

struct LiquidWaterProgress: View {
    let progress: Double

    @State private var waveOffset: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.blue.opacity(0.15))
                    .frame(height: 16)

                // Wave fill
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.6), Color.blue.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geo.size.width * progress, height: 16)
                    .overlay(
                        WaveShape(offset: waveOffset, progress: 0.5)
                            .fill(Color.white.opacity(0.2))
                            .frame(height: 16)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .animation(.easeInOut, value: progress)
            }
        }
        .frame(height: 16)
        .onAppear {
            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                waveOffset = .pi * 2
            }
        }
    }
}

// MARK: - Staggered Bar Fill

struct StaggeredBarFill: View {
    let items: [(String, Double, Color)]
    @State private var animated = false

    var body: some View {
        VStack(spacing: 8) {
            ForEach(Array(items.enumerated()), id: \.element.0) { index, item in
                HStack(spacing: 8) {
                    Text(item.0)
                        .font(.ctCaption)
                        .foregroundStyle(.ctTextSecondary)
                        .frame(width: 30, alignment: .trailing)

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(item.2.opacity(0.2))

                            RoundedRectangle(cornerRadius: 3)
                                .fill(item.2)
                                .frame(width: animated ? geo.size.width * min(item.1, 1.0) : 0)
                                .animation(
                                    .spring(response: 0.6, dampingFraction: 0.7)
                                        .delay(Double(index) * 0.1),
                                    value: animated
                                )
                        }
                    }
                    .frame(height: 8)

                    Text("\(Int(item.1 * 100))%")
                        .font(.system(size: 10))
                        .foregroundStyle(.ctTextSecondary)
                        .frame(width: 30)
                }
            }
        }
        .onAppear { animated = true }
    }
}
