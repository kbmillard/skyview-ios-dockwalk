import SwiftUI

struct ReceiveInventoryCardView: View {
    @Binding var item: ReceiveInventoryDraft
    let index: Int
    let onRemove: () -> Void

    var body: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Item \(index)")
                        .font(DockWalkTheme.headlineFont)
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
            }
        }
    }
}
