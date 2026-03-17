import SwiftUI

// MARK: - Shimmer Modifier

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    LinearGradient(
                        gradient: Gradient(colors: [
                            .clear,
                            Color.white.opacity(0.15),
                            .clear
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(width: geo.size.width * 2)
                    .offset(x: -geo.size.width + phase * geo.size.width * 3)
                }
            )
            .clipped()
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}

// MARK: - Skeleton Card

struct SkeletonCard: View {
    var height: CGFloat = 60
    var cornerRadius: CGFloat = 12

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(Color.ctSurfaceElevated)
            .frame(height: height)
            .shimmer()
    }
}

// MARK: - Skeleton Circle

struct SkeletonCircle: View {
    var size: CGFloat = 56

    var body: some View {
        Circle()
            .fill(Color.ctSurfaceElevated)
            .frame(width: size, height: size)
            .shimmer()
    }
}

// MARK: - Skeleton Line

struct SkeletonLine: View {
    var width: CGFloat? = nil
    var height: CGFloat = 14

    var body: some View {
        RoundedRectangle(cornerRadius: height / 2, style: .continuous)
            .fill(Color.ctSurfaceElevated)
            .frame(width: width, height: height)
            .shimmer()
    }
}

// MARK: - Dashboard Shimmer

struct DashboardShimmerView: View {
    var body: some View {
        VStack(spacing: 16) {
            // Calorie ring placeholder
            SkeletonCircle(size: 200)
                .padding(.vertical, 8)

            // Macro bars placeholder
            HStack(spacing: 12) {
                ForEach(0..<3, id: \.self) { _ in
                    VStack(spacing: 8) {
                        SkeletonCircle(size: 56)
                        SkeletonLine(width: 50, height: 10)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal)

            // Meal section placeholders
            ForEach(0..<3, id: \.self) { _ in
                VStack(spacing: 8) {
                    HStack {
                        SkeletonCircle(size: 28)
                        SkeletonLine(width: 100, height: 16)
                        Spacer()
                    }
                    SkeletonCard(height: 50)
                }
                .glassCard()
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - Analytics Shimmer

struct AnalyticsShimmerView: View {
    var body: some View {
        VStack(spacing: 16) {
            // Streak placeholder
            HStack(spacing: 16) {
                SkeletonCard(height: 80)
                SkeletonCard(height: 80)
            }
            .padding(.horizontal)

            // Chart placeholder
            SkeletonCard(height: 220)
                .padding(.horizontal)

            // Macro trend placeholder
            VStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { _ in
                    HStack {
                        SkeletonCircle(size: 8)
                        SkeletonLine(width: 60, height: 12)
                        Spacer()
                        SkeletonLine(width: 40, height: 12)
                    }
                }
            }
            .glassCard()
            .padding(.horizontal)
        }
    }
}

// MARK: - Food Search Shimmer

struct FoodSearchShimmerView: View {
    var body: some View {
        VStack(spacing: 12) {
            ForEach(0..<6, id: \.self) { _ in
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        SkeletonLine(width: 140, height: 14)
                        SkeletonLine(width: 80, height: 10)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        SkeletonLine(width: 60, height: 14)
                        SkeletonLine(width: 90, height: 10)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
    }
}

// MARK: - Recipe Shimmer

struct RecipeShimmerView: View {
    var body: some View {
        VStack(spacing: 16) {
            ForEach(0..<3, id: \.self) { _ in
                VStack(alignment: .leading, spacing: 12) {
                    SkeletonLine(width: 180, height: 16)
                    SkeletonLine(height: 12)
                    HStack(spacing: 12) {
                        SkeletonLine(width: 70, height: 10)
                        SkeletonLine(width: 60, height: 10)
                        SkeletonLine(width: 50, height: 10)
                    }
                }
                .glassCard()
            }
        }
        .padding(.horizontal)
    }
}
