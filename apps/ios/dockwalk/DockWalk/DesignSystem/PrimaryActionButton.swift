import SwiftUI

struct PrimaryActionButton: View {
    enum Style {
        case primary, secondary
    }

    let title: String
    var systemImage: String?
    var style: Style = .primary
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.title3.weight(.semibold))
                }
                Text(title)
                    .font(.system(.body, design: .rounded).weight(.semibold))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 20)
            .foregroundStyle(foreground)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: DockWalkTheme.cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DockWalkTheme.cornerRadius, style: .continuous)
                    .stroke(style == .secondary ? DockWalkTheme.cardBorder : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(.isButton)
    }

    private var foreground: Color {
        style == .primary ? .white : DockWalkTheme.textPrimary
    }

    private var background: some ShapeStyle {
        switch style {
        case .primary:
            return AnyShapeStyle(DockWalkTheme.accent)
        case .secondary:
            return AnyShapeStyle(DockWalkTheme.cardBackground)
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        PrimaryActionButton(title: "Start Receiving", systemImage: "arrow.down.doc.fill") {}
        PrimaryActionButton(title: "Scan Item", systemImage: "barcode.viewfinder", style: .secondary) {}
    }
    .padding()
}
