import SwiftUI

/// 8pt horizontal shake over 0.3s - used for invalid input, blocked actions
struct RefuseShakeModifier: ViewModifier {
    @Binding var shake: Bool
    
    func body(content: Content) -> some View {
        content
            .offset(x: shake ? shakeOffset() : 0)
            .onChange(of: shake) { _, newValue in
                if newValue {
                    performShake()
                }
            }
    }
    
    private func shakeOffset() -> CGFloat {
        let progress = shakeProgress
        // Sine wave oscillation: starts at 0, peaks at 8pt, returns to 0
        return sin(progress * .pi * 4) * 8 * (1 - progress)
    }
    
    @State private var shakeProgress: Double = 0
    
    private func performShake() {
        shakeProgress = 0
        withAnimation(.linear(duration: 0.3)) {
            shakeProgress = 1.0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            shake = false
            shakeProgress = 0
        }
    }
}

extension View {
    func refuseShake(_ shake: Binding<Bool>) -> some View {
        self.modifier(RefuseShakeModifier(shake: shake))
    }
}
