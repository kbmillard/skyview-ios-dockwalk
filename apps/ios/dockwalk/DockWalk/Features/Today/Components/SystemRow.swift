import SwiftUI

/// Pattern C: System Row for Sync and Activity
/// Structurally same as StatusRowCard but with system-specific semantics
struct SystemRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let statusLabel: String?
    let statusColor: Color?
    let action: () -> Void
    
    init(
        icon: String,
        title: String,
        subtitle: String,
        statusLabel: String? = nil,
        statusColor: Color? = nil,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.statusLabel = statusLabel
        self.statusColor = statusColor
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: Tokens.Space.md) {
                // Leading icon circle
                ZStack {
                    Circle()
                        .fill(Tokens.Color.Accent.horizonSoft)
                        .frame(width: 40, height: 40)
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(Tokens.Color.Accent.horizon)
                }
                
                // Title + subtitle
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(Tokens.Font.titleCard)
                        .foregroundStyle(Tokens.Color.Ink.primary)
                    Text(subtitle)
                        .font(Tokens.Font.bodySecondary)
                        .foregroundStyle(Tokens.Color.Ink.secondary)
                }
                
                Spacer(minLength: Tokens.Space.base)
                
                // Status pill or label
                if let statusLabel = statusLabel {
                    if let statusColor = statusColor {
                        // Pill format for pending counts
                        Text(statusLabel)
                            .font(Tokens.Font.bodySecondary.weight(.semibold))
                            .foregroundStyle(statusColor)
                            .padding(.horizontal, Tokens.Space.sm)
                            .padding(.vertical, Tokens.Space.xs)
                            .background(
                                Capsule()
                                    .fill(Tokens.Color.Accent.horizonSoft)
                            )
                    } else {
                        // Text format for "Up to date"
                        Text(statusLabel)
                            .font(Tokens.Font.bodySecondary)
                            .foregroundStyle(Tokens.Color.Ink.secondary)
                    }
                }
                
                // Trailing chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Tokens.Color.Ink.tertiary)
            }
            .padding(Tokens.Space.base)
            .frame(minHeight: Tokens.TapTarget.minimum)
            .background(Tokens.Color.Surface.card)
            .clipShape(RoundedRectangle(cornerRadius: Tokens.Radius.card))
        }
        .buttonStyle(.plain)
    }
}
