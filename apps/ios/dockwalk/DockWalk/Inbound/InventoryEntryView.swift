import SwiftUI

/// Full-screen receive load item entry — same card layout as Inventory add, saved to load draft only.
struct InventoryEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppEnvironment.self) private var environment
    @Environment(FacilityConfigStore.self) private var facilityConfig
    @Environment(InboundSessionStore.self) private var inboundSession
    @Environment(InventoryCatalogStore.self) private var inventoryCatalog
    @Environment(PutawayCompletionStore.self) private var completionStore
    @Environment(OfflineSyncStore.self) private var syncStore

    @Binding var item: ReceiveInventoryDraft
    let loadId: String
    let onSave: () -> Bool
    let onCancel: () -> Void

    @State private var showValidationAlert = false
    @State private var savedAwaitingPutaway = false
    @State private var showPutawayScanner = false
    @State private var putawayError: String?

    private var canSave: Bool {
        ShipmentDetailViewModel.validate(item)
    }

    private var stagingCode: String {
        let configured = facilityConfig.defaultReceiveLocation().trimmingCharacters(in: .whitespacesAndNewlines)
        if !configured.isEmpty { return configured }
        return item.location.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isAtStaging: Bool {
        let loc = item.location.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !loc.isEmpty else { return false }
        if stagingCode.isEmpty { return true }
        return loc.compare(stagingCode, options: .caseInsensitive) == .orderedSame
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DockWalkTheme.sectionSpacing) {
                    if savedAwaitingPutaway {
                        putawaySection
                    } else {
                        entryForm
                    }
                }
                .padding(DockWalkTheme.screenPadding)
            }
            .background(DockWalkTheme.background)
            .navigationTitle(savedAwaitingPutaway ? "Put away" : "Receive item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(savedAwaitingPutaway ? "Done" : "Cancel") {
                        if !savedAwaitingPutaway { onCancel() }
                        dismiss()
                    }
                }
            }
            .alert("Incomplete Item", isPresented: $showValidationAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Enter SKU or UPC, part name, CS and/or EA/CS, and location before saving.")
            }
            .onAppear {
                let defaultLoc = facilityConfig.defaultReceiveLocation()
                if item.location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, !defaultLoc.isEmpty {
                    item.location = defaultLoc
                }
            }
            .sheet(isPresented: $showPutawayScanner) {
                BarcodeScannerSheet(title: "Scan storage bin") { result in
                    showPutawayScanner = false
                    Task { await runPutaway(bin: result.value) }
                }
            }
        }
    }

    private var entryForm: some View {
        Group {
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
                    if isAtStaging {
                        savedAwaitingPutaway = true
                    } else {
                        dismiss()
                    }
                } else {
                    showValidationAlert = true
                }
            }
            .disabled(!canSave)
        }
    }

    private var putawaySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionCard {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Saved at \(stagingCode.isEmpty ? item.location : stagingCode)")
                        .font(DockWalkTheme.bodyFont.weight(.semibold))
                    Text(item.upc)
                        .font(.system(.body, design: .monospaced))
                    Text("Scan a storage bin to put this line away.")
                        .font(DockWalkTheme.captionFont)
                        .foregroundStyle(DockWalkTheme.textSecondary)
                }
            }
            PrimaryActionButton(title: "Scan storage bin", systemImage: "barcode.viewfinder") {
                putawayError = nil
                showPutawayScanner = true
            }
            if let putawayError {
                Text(putawayError)
                    .font(DockWalkTheme.captionFont)
                    .foregroundStyle(DockWalkTheme.warning)
            }
        }
    }

    private func runPutaway(bin: String) async {
        guard let card = PutawayUPCCard.from(receive: item, shipmentId: loadId) else {
            putawayError = "Could not build putaway card."
            return
        }
        let result = await PutawayMovementService.apply(
            card: card,
            toLocation: bin,
            facilityConfig: facilityConfig,
            inboundSession: inboundSession,
            catalog: inventoryCatalog,
            completionStore: completionStore,
            syncStore: syncStore,
            environment: environment
        )
        switch result {
        case .success:
            dismiss()
        case .failure(let error):
            putawayError = error.localizedDescription
        }
    }
}
