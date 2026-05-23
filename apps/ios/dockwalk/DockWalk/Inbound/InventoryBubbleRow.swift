import SwiftUI

struct InventoryBubbleRow: View {
    let item: ReceiveInventoryDraft
    let action: () -> Void
    
    private var primaryIdentifier: String {
        if !item.sku.isEmpty {
            return item.sku
        }
        return item.upc
    }
    
    private var partNameDisplay: String {
        item.itemName.isEmpty ? "—" : item.itemName
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(primaryIdentifier)
                        .font(DockWalkTheme.bodyFont.weight(.semibold))
                        .foregroundStyle(DockWalkTheme.textPrimary)
                        .lineLimit(1)
                    
                    Text(partNameDisplay)
                        .font(DockWalkTheme.captionFont)
                        .foregroundStyle(DockWalkTheme.textSecondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    Text(item.quantityDisplay)
                        .font(DockWalkTheme.captionFont.weight(.medium))
                        .foregroundStyle(DockWalkTheme.textSecondary)
                    
                    Image(systemName: "chevron.right")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(DockWalkTheme.textSecondary)
                }
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
            .background(DockWalkTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
