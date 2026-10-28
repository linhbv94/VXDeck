import SwiftUI

public struct DropIndicatorLine: View {
    public init() {}

    public var body: some View {
        ZStack {
            // Neon cyan glow
            Capsule()
                .fill(Color.cyan.opacity(0.6))
                .frame(width: 6, height: 74)
                .blur(radius: 2.5)

            // Crisp line
            Capsule()
                .fill(Color.cyan)
                .frame(width: 3, height: 74)

            // Top circle indicator
            Circle()
                .fill(Color.cyan)
                .frame(width: 7, height: 7)
                .offset(y: -37)

            // Bottom circle indicator
            Circle()
                .fill(Color.cyan)
                .frame(width: 7, height: 7)
                .offset(y: 37)
        }
        .allowsHitTesting(false)
        .transition(.opacity.animation(.easeInOut(duration: 0.12)))
    }
}
