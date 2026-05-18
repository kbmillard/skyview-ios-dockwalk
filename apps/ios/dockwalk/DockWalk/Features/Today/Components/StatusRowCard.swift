import SwiftUI

/// Pattern A: Status Row Card for workflow states
/// Used for: Scheduled, Checked In, Staged/Pending, Assigned, Complete
struct StatusRowCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let count: Int
    let countColor: Color?
    let action: () -> Void
    
    init(
        icon: String,
        title: String,
        subtitle: String,
        count: Int,
        countColor: Color? = Tokens.Color.Accent.horizon,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.count = count
        self.countColor = countColor
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
                
                // Count badge or empty state
                if count > 0 {
                    Text("\(count)")
                        .font(Tokens.Font.bodySecondary.weight(.semibold))
                        .foregroundStyle(countColor ?? Tokens.Color.Accent.horizon)
                        .padding(.horizontal, Tokens.Space.sm)
                        .padding(.vertical, Tokens.Space.xs)
                        .background(
                            Capsule()
                                .fill(Tokens.Color.Accent.horizonSoft)
                        )
                } else {
                    Text("—")
                        .font(Tokens.Font.bodySecondary)
                        .foregroundStyle(Tokens.Color.Ink.tertiary)
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
