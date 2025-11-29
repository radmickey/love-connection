import SwiftUI

struct HeartAnimationView: View {
    let isAnimating: Bool
    @State private var scale: CGFloat = 1.0
    @State private var rotation: Double = 0

    var body: some View {
        Image(systemName: "heart.fill")
            .font(.system(size: 140))
            .foregroundStyle(
                LinearGradient(
                    colors: [.pink, .red],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .scaleEffect(scale)
            .rotationEffect(.degrees(rotation))
            .onChange(of: isAnimating, perform: { animating in
                if animating {
                    startAnimation()
                } else {
                    stopAnimation()
                }
            })
    }

    private func startAnimation() {
        // Ensure values are valid before animating
        if scale.isNaN || scale.isInfinite {
            scale = 1.0
        }
        if rotation.isNaN || rotation.isInfinite {
            rotation = 0
        }

        withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
            scale = 1.2
        }
        withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
            rotation = 360
        }
    }

    private func stopAnimation() {
        // Ensure values are valid before animating
        if scale.isNaN || scale.isInfinite {
            scale = 1.0
        }
        if rotation.isNaN || rotation.isInfinite {
            rotation = 0
        }

        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            scale = 1.0
            rotation = 0
        }
    }
}

