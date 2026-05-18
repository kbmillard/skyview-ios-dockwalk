import SwiftUI

/// Large card row for Today command center and similar hubs.
struct OperationalDestinationCard: View {
    let title: String
    let subtitle: String
    let systemImage: String
    var statusLabel: String?
    var statusTone: StatusChip.Tone = .neutral
    var action: (() -> Void)?

    var body: some View {
        Group {
            if let action {
                Button(action: action) {
                    cardBody
                }
                .buttonStyle(.plain)
            } else {
                cardBody
            }
        }
    }

    private var cardBody: some View {
        SectionCard {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: systemImage)
                    .font(.title2)
                    .foregroundStyle(DockWalkTheme.accent)
                    .frame(width: 36)

                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(DockWalkTheme.headlineFont)
                        .foregroundStyle(DockWalkTheme.textPrimary)
                    Text(subtitle)
                        .font(DockWalkTheme.captionFont)
                        .foregroundStyle(DockWalkTheme.textSecondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer(minLength: 0)

                if let statusLabel {
                    StatusChip(label: statusLabel, tone: statusTone)
                }

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(DockWalkTheme.textSecondary)
            }
        }
    }
}
