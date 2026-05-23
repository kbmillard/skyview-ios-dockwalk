import SwiftUI

/// Full-screen receive load item entry — same card layout as Inventory add, saved to load draft only.
struct InventoryEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var item: ReceiveInventoryDraft
    let onSave: () -> Bool
    let onCancel: () -> Void

    @State private var showValidationAlert = false

    private var canSave: Bool {
        ShipmentDetailViewModel.validate(item)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DockWalkTheme.sectionSpacing) {
                    SectionCard {
                        InventoryItemFormFields(
                            sku: $item.sku,
                            upc: $item.upc,
                            itemName: $item.itemName,
                            partDescription: $item.partDescription,
                            quantity: $item.quantity,
                            casesQty: $item.casesQty,
                            eachesQty: $item.eachesQty,
                            location: $item.location,
                            selectedStatus: $item.status,
                            quantityEntryStyle: .casesAndEaches,
                            showCatalogSuggestions: false
                        )
                    }

                    PrimaryActionButton(title: "Save", systemImage: "checkmark.circle.fill") {
                        if onSave() {
                            dismiss()
                        } else {
                            showValidationAlert = true
                        }
                    }
                    .disabled(!canSave)
                }
                .padding(DockWalkTheme.screenPadding)
            }
            .background(DockWalkTheme.background)
            .navigationTitle("Receive item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                        dismiss()
                    }
                }
            }
            .alert("Incomplete Item", isPresented: $showValidationAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Enter SKU or UPC, part name, CS and/or EA/CS, and location before saving.")
            }
        }
    }
}
