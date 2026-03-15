import SwiftUI

struct RulerPicker: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    var onUserScroll: (() -> Void)? = nil

    @State private var scrolledID: Int?
    @State private var isProgrammaticChange = false
    private let tickSpacing: CGFloat = 6
    private let majorEvery = 10

    private var stepCount: Int {
        Int((range.upperBound - range.lowerBound) / step)
    }

    private func indexToValue(_ index: Int) -> Double {
        let v = range.lowerBound + Double(index) * step
        return (v * 10).rounded() / 10
    }

    private func valueToIndex(_ val: Double) -> Int {
        Int(((val - range.lowerBound) / step).rounded())
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(alignment: .bottom, spacing: tickSpacing) {
                ForEach(0...stepCount, id: \.self) { i in
                    let isMajor = i % majorEvery == 0
                    let isMid = i % 5 == 0 && !isMajor

                    VStack(spacing: 1) {
                        if isMajor {
                            Text("\(Int(range.lowerBound + Double(i) * step))")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundStyle(.ctTextSecondary)
                                .fixedSize()
                        }
                        RoundedRectangle(cornerRadius: 0.5)
                            .fill(isMajor ? Color.ctTextPrimary : isMid ? Color.ctTextSecondary : Color.ctTextTertiary.opacity(0.5))
                            .frame(width: 1, height: isMajor ? 20 : isMid ? 13 : 7)
                    }
                    .frame(width: tickSpacing)
                    .id(i)
                }
            }
            .scrollTargetLayout()
        }
        .scrollPosition(id: $scrolledID, anchor: .center)
        .scrollTargetBehavior(.viewAligned)
        .frame(height: 40)
        .overlay {
            Rectangle()
                .fill(Color.ctAccent)
                .frame(width: 2, height: 26)
                .allowsHitTesting(false)
        }
        .onChange(of: scrolledID) { _, newID in
            guard let id = newID else { return }
            if isProgrammaticChange { return }
            let clamped = min(max(id, 0), stepCount)
            let newValue = indexToValue(clamped)
            if abs(newValue - value) >= step * 0.5 {
                value = newValue
                onUserScroll?()
                HapticManager.selection()
            }
        }
        .onChange(of: value) { _, newVal in
            let targetIndex = valueToIndex(newVal)
            if scrolledID != targetIndex {
                isProgrammaticChange = true
                scrolledID = targetIndex
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isProgrammaticChange = false
                }
            }
        }
        .onAppear {
            isProgrammaticChange = true
            scrolledID = valueToIndex(value)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isProgrammaticChange = false
            }
        }
    }
}
