import SwiftUI

struct HeartAnimationView: View {
    let isAnimating: Bool
    @State private var scale: CGFloat = 1.0

    var body: some View {
        Image(systemName: "heart.fill")
            .font(.system(size: 120))
            .foregroundColor(.red)
            .scaleEffect(scale)
            .onChange(of: isAnimating, perform: { animating in
                if animating {
                    startAnimation()
                } else {
                    stopAnimation()
                }
            })
    }

    private func startAnimation() {
        withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
            scale = 1.15
        }
    }

    private func stopAnimation() {
        withAnimation(.easeInOut(duration: 0.3)) {
            scale = 1.0
        }
    }
}

