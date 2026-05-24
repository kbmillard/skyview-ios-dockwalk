import SwiftUI

/// Compact saved-step bubble for the putaway hub (mirrors `InventoryBubbleRow`).
struct PutawayStepBubbleRow: View {
    let draft: PutawayConfirmDraft
    let expectedValue: String?
    let onTap: () -> Void

    private var primaryText: String {
        switch draft.step {
        case .quantity:
            if let qty = draft.confirmedQty {
                return formatQuantity(qty)
            }
            return draft.scannedValue
        default:
            return draft.scannedValue.isEmpty ? "—" : draft.scannedValue
        }
    }

    private var matchesExpected: Bool {
        guard let expected = expectedValue, !expected.isEmpty else { return true }
        return draft.scannedValue.trimmingCharacters(in: .whitespacesAndNewlines)
            .compare(expected, options: .caseInsensitive) == .orderedSame
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: draft.step.systemImage)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(DockWalkTheme.accent)
                    .frame(width: 28, alignment: .center)

                VStack(alignment: .leading, spacing: 2) {
                    Text(draft.step.displayName)
                        .font(DockWalkTheme.captionFont)
                        .foregroundStyle(DockWalkTheme.textSecondary)
                    Text(primaryText)
                        .font(DockWalkTheme.bodyFont.weight(.semibold))
                        .foregroundStyle(DockWalkTheme.textPrimary)
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: matchesExpected ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .foregroundStyle(matchesExpected ? DockWalkTheme.accent : DockWalkTheme.warning)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
            .background(DockWalkTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func formatQuantity(_ value: Double) -> String {
        value == floor(value) ? String(Int(value)) : String(value)
    }
}
