import SwiftUI

/// Add inventory from scan-not-found flow; saves to local catalog.
struct InventoryAddSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(InventoryCatalogStore.self) private var catalog
    @Environment(AppEnvironment.self) private var appEnvironment

    let initialCode: String
    let onSaved: (InventoryItem) -> Void

    @State private var sku = ""
    @State private var upc = ""
    @State private var partDescription = ""
    @State private var itemName = ""
    @State private var quantity = "1"
    @State private var casesQty = ""
    @State private var eachesQty = ""
    @State private var location = ""
    @State private var selectedStatus: InventoryStatus = .available
    @State private var isSaving = false
    @State private var errorMessage: String?

    private var skuSuggestions: [InventoryItem] {
        catalog.suggestions(matchingSKU: sku)
    }

    private var partDescriptionSuggestions: [InventoryItem] {
        catalog.suggestions(matchingPartDescription: partDescription)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DockWalkTheme.sectionSpacing) {
                    SectionCard {
                        InventoryItemFormFields(
                            sku: $sku,
                            upc: $upc,
                            itemName: $itemName,
                            partDescription: $partDescription,
                            quantity: $quantity,
                            casesQty: $casesQty,
                            eachesQty: $eachesQty,
                            location: $location,
                            selectedStatus: $selectedStatus,
                            quantityEntryStyle: .singleQty,
                            showCatalogSuggestions: true,
                            skuSuggestions: skuSuggestions,
                            partDescriptionSuggestions: partDescriptionSuggestions,
                            onSelectSKU: applyFromSKUSuggestion,
                            onSelectPartDescription: applyFromPartDescriptionSuggestion
                        )
                    }

                    if let errorMessage {
                        Text(errorMessage)
                            .font(DockWalkTheme.captionFont)
                            .foregroundStyle(DockWalkTheme.danger)
                    }

                    PrimaryActionButton(title: "Save", systemImage: "checkmark.circle.fill") {
                        save()
                    }
                    .disabled(!isFormValid || isSaving)
                }
                .padding(DockWalkTheme.screenPadding)
            }
            .background(DockWalkTheme.background)
            .navigationTitle("Add inventory")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .disabled(isSaving)
                }
            }
            .onAppear {
                let code = initialCode.trimmingCharacters(in: .whitespacesAndNewlines)
                upc = code
                if location.isEmpty { location = "RECV-STAGE" }
            }
        }
    }

    private var isFormValid: Bool {
        !sku.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !itemName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && (Int(quantity.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0) > 0
    }

    private func applyFromSKUSuggestion(_ catalogItem: InventoryItem) {
        sku = catalogItem.sku
        partDescription = catalogItem.partDescription ?? ""
        itemName = catalogItem.itemName
    }

    private func applyFromPartDescriptionSuggestion(_ catalogItem: InventoryItem) {
        partDescription = catalogItem.partDescription ?? ""
        sku = catalogItem.sku
        itemName = catalogItem.itemName
    }

    private func save() {
        guard let qty = Int(quantity.trimmingCharacters(in: .whitespacesAndNewlines)), qty > 0 else {
            errorMessage = "Quantity must be a positive number"
            return
        }
        errorMessage = nil
        isSaving = true

        let trimmedSKU = sku.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedUPC = upc.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPart = partDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedName = itemName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedLocation = location.trimmingCharacters(in: .whitespacesAndNewlines)

        let item = InventoryItem(
            id: UUID().uuidString,
            sku: trimmedSKU,
            upc: trimmedUPC.isEmpty ? nil : trimmedUPC,
            partDescription: trimmedPart.isEmpty ? nil : trimmedPart,
            itemName: trimmedName,
            description: trimmedName,
            quantity: qty,
            location: trimmedLocation,
            status: selectedStatus,
            onHand: qty,
            reserved: 0
        )

        catalog.add(item)
        Haptics.scanSuccess()

        Task {
            let client = appEnvironment.makeAPIClient()
            try? await client.addInventoryItem(item)
            await MainActor.run {
                isSaving = false
                onSaved(item)
                dismiss()
            }
        }
    }
}
