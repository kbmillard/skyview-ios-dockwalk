import SwiftUI

/// Swipe-to-complete affordance for putaway tasks (mirrors `FinalizeLoadButton`).
struct CompletePutawayButton: View {
    let isEnabled: Bool
    let onComplete: () -> Void

    @State private var dragOffset: CGFloat = 0
    @GestureState private var isDragging = false

    private let buttonHeight: CGFloat = 56
    private let thumbWidth: CGFloat = 52
    private let threshold: CGFloat = 0.85

    private func progress(in width: CGFloat) -> CGFloat {
        let available = max(width - thumbWidth, 1)
        return min(dragOffset / available, 1.0)
    }

    private func isComplete(in width: CGFloat) -> Bool {
        progress(in: width) >= threshold
    }

    var body: some View {
        GeometryReader { geometry in
            let p = progress(in: geometry.size.width)
            let complete = isComplete(in: geometry.size.width)
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: buttonHeight / 2, style: .continuous)
                    .fill(isEnabled ? DockWalkTheme.accentMuted : DockWalkTheme.cardBackground)

                RoundedRectangle(cornerRadius: buttonHeight / 2, style: .continuous)
                    .fill(DockWalkTheme.accent.opacity(p * 0.3))
                    .frame(width: dragOffset + thumbWidth)

                HStack {
                    Spacer()
                    Text(label(complete: complete))
                        .font(DockWalkTheme.bodyFont.weight(.semibold))
                        .foregroundStyle(isEnabled ? DockWalkTheme.accent : DockWalkTheme.textSecondary)
                    Spacer()
                }
                .padding(.trailing, thumbWidth)

                Circle()
                    .fill(isEnabled ? DockWalkTheme.accent : DockWalkTheme.textSecondary)
                    .frame(width: thumbWidth, height: thumbWidth)
                    .overlay {
                        Image(systemName: complete ? "checkmark" : "chevron.right")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.white)
                    }
                    .offset(x: dragOffset + 2)
                    .gesture(dragGesture(in: geometry))
            }
            .frame(height: buttonHeight)
            .opacity(isEnabled ? 1 : 0.6)
            .allowsHitTesting(isEnabled)
        }
        .frame(height: buttonHeight)
    }

    private func label(complete: Bool) -> String {
        if !isEnabled { return "Scan to-location and confirm qty first" }
        return complete ? "Release to complete" : "Swipe to complete putaway"
    }

    private func dragGesture(in geometry: GeometryProxy) -> some Gesture {
        DragGesture()
            .updating($isDragging) { _, state, _ in state = true }
            .onChanged { value in
                let maxDrag = geometry.size.width - thumbWidth - 4
                dragOffset = min(max(0, value.translation.width), maxDrag)
            }
            .onEnded { _ in
                if isComplete(in: geometry.size.width) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        dragOffset = geometry.size.width - thumbWidth - 4
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        onComplete()
                        withAnimation { dragOffset = 0 }
                    }
                } else {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        dragOffset = 0
                    }
                }
            }
    }
}

#Preview {
    VStack(spacing: 20) {
        CompletePutawayButton(isEnabled: true) { }
        CompletePutawayButton(isEnabled: false) { }
    }
    .padding()
}
