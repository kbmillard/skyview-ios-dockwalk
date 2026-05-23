import SwiftUI

struct FinalizeLoadButton: View {
    let onFinalize: () -> Void
    
    @State private var dragOffset: CGFloat = 0
    @State private var maxWidth: CGFloat = 0
    @GestureState private var isDragging = false
    
    private let buttonHeight: CGFloat = 56
    private let thumbWidth: CGFloat = 52
    private let threshold: CGFloat = 0.85
    
    private var progress: CGFloat {
        guard maxWidth > 0 else { return 0 }
        let availableWidth = maxWidth - thumbWidth
        return min(dragOffset / availableWidth, 1.0)
    }
    
    private var isComplete: Bool {
        progress >= threshold
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: buttonHeight / 2, style: .continuous)
                    .fill(DockWalkTheme.accentMuted)
                
                RoundedRectangle(cornerRadius: buttonHeight / 2, style: .continuous)
                    .fill(DockWalkTheme.accent.opacity(progress * 0.3))
                    .frame(width: dragOffset + thumbWidth)
                
                HStack {
                    Spacer()
                    Text(isComplete ? "Release to Finalize" : "Swipe to Finalize Load")
                        .font(DockWalkTheme.bodyFont.weight(.semibold))
                        .foregroundStyle(DockWalkTheme.accent)
                    Spacer()
                }
                .padding(.trailing, thumbWidth)
                
                Circle()
                    .fill(DockWalkTheme.accent)
                    .frame(width: thumbWidth, height: thumbWidth)
                    .overlay {
                        Image(systemName: isComplete ? "checkmark" : "chevron.right")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.white)
                    }
                    .offset(x: dragOffset + 2)
                    .gesture(
                        DragGesture()
                            .updating($isDragging) { _, state, _ in
                                state = true
                            }
                            .onChanged { value in
                                let maxDrag = geometry.size.width - thumbWidth - 4
                                dragOffset = min(max(0, value.translation.width), maxDrag)
                            }
                            .onEnded { _ in
                                if isComplete {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        dragOffset = geometry.size.width - thumbWidth - 4
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                        onFinalize()
                                        withAnimation {
                                            dragOffset = 0
                                        }
                                    }
                                } else {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        dragOffset = 0
                                    }
                                }
                            }
                    )
            }
            .frame(height: buttonHeight)
            .onAppear {
                maxWidth = geometry.size.width
            }
        }
        .frame(height: buttonHeight)
    }
}

#Preview {
    VStack(spacing: 20) {
        FinalizeLoadButton {
            print("Finalized!")
        }
        .padding()
    }
}
