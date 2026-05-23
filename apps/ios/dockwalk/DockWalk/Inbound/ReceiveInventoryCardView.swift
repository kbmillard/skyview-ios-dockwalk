import SwiftUI

struct ReceiveInventoryCardView: View {
    @Environment(InventoryCatalogStore.self) private var inventoryCatalog
    @Binding var item: ReceiveInventoryDraft
    let index: Int
    let onSave: () -> Void
    let onRemove: () -> Void

    private var skuSuggestions: [InventoryItem] {
        inventoryCatalog.suggestions(matchingSKU: item.sku)
    }

    private var partDescriptionSuggestions: [InventoryItem] {
        inventoryCatalog.suggestions(matchingPartDescription: item.partDescription)
    }

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

                FormCatalogSuggestRow(
                    label: "SKU",
                    kind: .sku,
                    text: $item.sku,
                    placeholder: "",
                    suggestions: skuSuggestions,
                    onSelect: applyFromSKUSuggestion
                )
                FormValueRow(label: "UPC", text: $item.upc, placeholder: "", autocapitalizationType: .allCharacters)
                FormValueRow(label: "Part name", text: $item.itemName, placeholder: "")
                FormCatalogSuggestRow(
                    label: "Part description",
                    kind: .partDescription,
                    text: $item.partDescription,
                    placeholder: "Optional",
                    suggestions: partDescriptionSuggestions,
                    onSelect: applyFromPartDescriptionSuggestion
                )
                FormReceiveCasesEachesRow(
                    casesQty: $item.casesQty,
                    eachesQty: $item.eachesQty
                )
                FormValueRow(label: "Location", text: $item.location, placeholder: "", autocapitalizationType: .allCharacters)

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

    /// SKU autoguess: part description + part name only — never UPC.
    private func applyFromSKUSuggestion(_ catalogItem: InventoryItem) {
        item.sku = catalogItem.sku
        item.partDescription = catalogItem.partDescription ?? ""
        item.itemName = catalogItem.itemName
    }

    /// Part description autoguess: same fields, never UPC.
    private func applyFromPartDescriptionSuggestion(_ catalogItem: InventoryItem) {
        item.partDescription = catalogItem.partDescription ?? ""
        item.sku = catalogItem.sku
        item.itemName = catalogItem.itemName
    }
}
