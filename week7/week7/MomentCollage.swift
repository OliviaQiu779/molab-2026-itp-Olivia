import SwiftUI

private enum QudgeStyle {
    static let background = Color(red: 0.025, green: 0.027, blue: 0.035)
    static let surface = Color(red: 0.075, green: 0.08, blue: 0.095)
    static let accent = Color(red: 0.83, green: 1.0, blue: 0.24)
    static let border = Color.white.opacity(0.15)
}

struct MomentCollage: View {
    let items: [StackItem]
    let onTap: () -> Void

    @State private var shift = 0

    private let cardWidth: CGFloat = 190
    private let cardHeight: CGFloat = 260
    private let radiusX: CGFloat = 102
    private let radiusY: CGFloat = 36

    private var deck: [StackItem] {
        let pending = items.filter { $0.isPending }
        let posted = items.filter { !$0.isPending }
        return pending + posted
    }

    var body: some View {
        GeometryReader { geometry in
            let count = deck.count

            ZStack {
                // Subtle orbital guide
                Ellipse()
                    .stroke(
                        QudgeStyle.accent.opacity(0.12),
                        lineWidth: 1
                    )
                    .frame(width: radiusX * 2.3, height: radiusY * 2.1)
                    .offset(y: 18)

                ForEach(Array(deck.enumerated()), id: \.element.id) { index, item in
                    let angle = angleFor(index: index, count: count)
                    let depth = cos(angle)
                    let frontness = (depth + 1) / 2

                    let x = sin(angle) * radiusX
                    let y = depth * radiusY

                    let scale = 0.70 + 0.30 * frontness
                    let opacity = 0.55 + 0.45 * frontness

                    card(item, compact: frontness < 0.72)
                        .frame(
                            width: cardWidth,
                            height: cardHeight
                        )
                        .scaleEffect(scale)
                        .rotation3DEffect(
                            .degrees(-sin(angle) * 38),
                            axis: (x: 0, y: 1, z: 0),
                            perspective: 0.65
                        )
                        .rotationEffect(
                            .degrees(-sin(angle) * 5)
                        )
                        .offset(
                            x: x,
                            y: y
                        )
                        .opacity(opacity)
                        .zIndex(depth)
                        .allowsHitTesting(frontness > 0.35)
                        .onTapGesture {
                            onTap()
                        }
                }
            }
            .frame(
                width: geometry.size.width,
                height: geometry.size.height
            )
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 20)
                    .onEnded { value in
                        guard abs(value.translation.width) > 35 else {
                            return
                        }

                        withAnimation(
                            .spring(
                                response: 0.55,
                                dampingFraction: 0.78
                            )
                        ) {
                            shift += value.translation.width < 0 ? 1 : -1
                        }
                    }
            )
        }
        .frame(height: 390)
        .background(QudgeStyle.background)
        .clipped()
        .overlay(alignment: .bottom) {
            Text("DRAG TO EXPLORE")
                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                .tracking(3)
                .foregroundStyle(.white.opacity(0.38))
                .padding(.bottom, 2)
        }
    }

    private func angleFor(index: Int, count: Int) -> Double {
        guard count > 0 else { return 0 }

        let step = 2 * Double.pi / Double(count)
        return Double(index + shift) * step
    }

    @ViewBuilder
    private func card(
        _ item: StackItem,
        compact: Bool
    ) -> some View {
        switch item {
        case .photo(let capture, let friend):
            PhotoCard(
                capture: capture,
                friend: friend,
                compact: compact
            )

        case .pending(let friend):
            PendingCard(
                friend: friend,
                compact: compact
            )
        }
    }
}
