import SwiftUI

struct ReceiveInventoryCardView: View {
    @Binding var item: ReceiveInventoryDraft
    let index: Int
    let onSave: () -> Void
    let onRemove: () -> Void

    var body: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    HStack(spacing: 8) {
                        Text("Item \(index)")
                            .font(DockWalkTheme.headlineFont)
                        if item.isSaved {
                            Label("Saved", systemImage: "checkmark.circle.fill")
                                .font(DockWalkTheme.captionFont.weight(.semibold))
                                .foregroundStyle(DockWalkTheme.accent)
                        }
                    }
                    Spacer()
                    Button(role: .destructive, action: onRemove) {
                        Image(systemName: "trash")
                            .font(.body)
                    }
                }

                FormValueRow(label: "SKU", text: $item.sku, placeholder: "SKU", autocapitalization: .characters)
                FormValueRow(label: "Part #", text: $item.partNumber, placeholder: "Optional")
                FormValueRow(label: "Item name", text: $item.itemName, placeholder: "Description")
                FormValueRow(label: "Qty", text: $item.quantity, placeholder: "0", keyboardType: .numberPad)
                FormValueRow(label: "Location", text: $item.location, placeholder: "Bin", autocapitalization: .characters)

                PrimaryActionButton(
                    title: item.isSaved ? "Update" : "Save",
                    systemImage: item.isSaved ? "arrow.clockwise" : "checkmark",
                    style: item.isSaved ? .secondary : .primary
                ) {
                    onSave()
                }
            }
        }
    }
}
