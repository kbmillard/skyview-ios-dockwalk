import SwiftUI

/// Shared inventory create/edit fields (Inventory add sheet + receive load entry).
struct InventoryItemFormFields: View {
    enum QuantityEntryStyle {
        case singleQty
        case casesAndEaches
    }

    @Binding var sku: String
    @Binding var upc: String
    @Binding var itemName: String
    @Binding var partDescription: String
    @Binding var quantity: String
    @Binding var casesQty: String
    @Binding var eachesQty: String
    @Binding var location: String
    @Binding var selectedStatus: InventoryStatus
    var quantityEntryStyle: QuantityEntryStyle = .singleQty
    var showCatalogSuggestions: Bool = true
    var skuSuggestions: [InventoryItem] = []
    var partDescriptionSuggestions: [InventoryItem] = []
    var onSelectSKU: ((InventoryItem) -> Void)?
    var onSelectPartDescription: ((InventoryItem) -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if showCatalogSuggestions, let onSelectSKU {
                FormCatalogSuggestRow(
                    label: "SKU",
                    kind: .sku,
                    text: $sku,
                    placeholder: "",
                    suggestions: skuSuggestions,
                    onSelect: onSelectSKU
                )
            } else {
                FormValueRow(label: "SKU", text: $sku, placeholder: "", autocapitalizationType: .allCharacters)
            }

            FormValueRow(label: "UPC", text: $upc, placeholder: "", autocapitalizationType: .allCharacters)
            FormValueRow(label: "Part name", text: $itemName, placeholder: "")

            if showCatalogSuggestions, let onSelectPartDescription {
                FormCatalogSuggestRow(
                    label: "Part description",
                    kind: .partDescription,
                    text: $partDescription,
                    placeholder: "Optional",
                    suggestions: partDescriptionSuggestions,
                    onSelect: onSelectPartDescription
                )
            } else {
                FormValueRow(label: "Part description", text: $partDescription, placeholder: "Optional")
            }

            quantitySection
            FormValueRow(label: "Location", text: $location, placeholder: "", autocapitalizationType: .allCharacters)

            statusPicker
        }
    }

    @ViewBuilder
    private var quantitySection: some View {
        switch quantityEntryStyle {
        case .singleQty:
            FormValueRow(label: "Qty", text: $quantity, placeholder: "", keyboardType: .numberPad)
        case .casesAndEaches:
            FormReceiveCasesEachesRow(casesQty: $casesQty, eachesQty: $eachesQty)
        }
    }

    private var statusPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Status")
                .font(DockWalkTheme.captionFont)
                .foregroundStyle(DockWalkTheme.textSecondary)
            HStack(spacing: 8) {
                ForEach(InventoryStatus.allCases, id: \.rawValue) { status in
                    Button {
                        selectedStatus = status
                    } label: {
                        Text(status.displayName)
                            .font(DockWalkTheme.captionFont.weight(.semibold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(selectedStatus == status ? DockWalkTheme.accent : DockWalkTheme.cardBackground)
                            .foregroundStyle(selectedStatus == status ? .white : DockWalkTheme.textPrimary)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
