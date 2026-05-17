import SwiftUI

struct StatusChip: View {
    enum Tone {
        case neutral, info, success, warning, danger

        var foreground: Color {
            switch self {
            case .neutral: return DockWalkTheme.textSecondary
            case .info: return DockWalkTheme.accent
            case .success: return DockWalkTheme.success
            case .warning: return DockWalkTheme.warning
            case .danger: return DockWalkTheme.danger
            }
        }

        var background: Color {
            foreground.opacity(0.14)
        }
    }

    let label: String
    var tone: Tone = .neutral

    var body: some View {
        Text(label)
            .font(.system(.caption, design: .rounded).weight(.semibold))
            .foregroundStyle(tone.foreground)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(tone.background)
            .clipShape(Capsule())
    }
}

#Preview {
    HStack {
        StatusChip(label: "Scheduled", tone: .info)
        StatusChip(label: "Receiving", tone: .warning)
        StatusChip(label: "Complete", tone: .success)
    }
    .padding()
}
