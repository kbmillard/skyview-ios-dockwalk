import SwiftUI

struct InventoryHomeView: View {
    @Environment(AppEnvironment.self) private var environment
    @Environment(ScannerPreferencesStore.self) private var scannerPreferences
    @Environment(InventoryScannerCoordinator.self) private var inventoryScannerCoordinator
    @Environment(InventoryCatalogStore.self) private var inventoryCatalog
    @Environment(InboundSessionStore.self) private var inboundSession
    @Environment(PutawayCompletionStore.self) private var completionStore
    @Environment(FacilityConfigStore.self) private var facilityConfig
    @Environment(OfflineSyncStore.self) private var syncStore

    @State private var viewModel = InventoryViewModel()
    @State private var showScanner = false
    @State private var showAddInventory = false
    @State private var selectedItem: InventoryItem?
    @State private var lastHandledScanToken = 0
    @State private var pendingPutawayCard: PutawayUPCCard?
    @State private var showPutawaySheet = false
    @State private var showBinScanner = false
    @State private var putawayError: String?
    @State private var putawaySuccessMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchField
                    .padding(DockWalkTheme.screenPadding)

                if !viewModel.searchQuery.isEmpty {
                    itemsSection
                } else {
                    stagingSnapshotSection
                }
            }
            .background(DockWalkTheme.background)
            .navigationTitle("Inventory")
            .sheet(isPresented: $showScanner) {
                BarcodeScannerSheet(
                    title: "Scan UPC",
                    applyStyle: .direct,
                    manualEntryPlaceholder: "UPC"
                ) { result in
                    handleScannedCode(result.value)
                }
            }
            .sheet(isPresented: $showAddInventory) {
                InventoryAddSheet(initialCode: viewModel.searchQuery) { _ in
                    viewModel.refreshFromCatalog()
                }
            }
            .sheet(item: $selectedItem) { item in
                InventoryItemDetailView(item: item)
            }
            .sheet(isPresented: $showPutawaySheet) {
                if let pendingPutawayCard {
                    InventoryPutawaySheet(
                        card: pendingPutawayCard,
                        errorMessage: putawayError,
                        onPutAway: {
                            putawayError = nil
                            showPutawaySheet = false
                            showBinScanner = true
                        },
                        onDismiss: {
                            self.pendingPutawayCard = nil
                            putawayError = nil
                        }
                    )
                }
            }
            .sheet(isPresented: $showBinScanner) {
                BarcodeScannerSheet(title: "Scan storage bin") { result in
                    showBinScanner = false
                    Task { await applyPutaway(to: result.value) }
                }
            }
            .dismissScannerSheetWhenInactive(scannerPreferences, isPresented: $showScanner)
            .dismissScannerSheetWhenInactive(scannerPreferences, isPresented: $showBinScanner)
            .onAppear {
                viewModel.refreshFromCatalog()
                handleFloatingScanRequestIfNeeded()
            }
            .onChange(of: inventoryScannerCoordinator.openScannerToken) { _, _ in
                handleFloatingScanRequestIfNeeded()
            }
            .onChange(of: inventoryCatalog.revision) { _, _ in
                viewModel.refreshFromCatalog()
            }
            .onChange(of: inboundSession.receivedInventoryRevision) { _, _ in
                putawaySuccessMessage = nil
            }
            .onChange(of: completionStore.revision) { _, _ in
                putawaySuccessMessage = nil
            }
        }
    }

    private var stagingSections: [PutawayCardQueueBuilder.StagingLocationSection] {
        PutawayCardQueueBuilder.groupedPendingCards(
            inboundSession: inboundSession,
            completionStore: completionStore,
            facilityConfig: facilityConfig
        )
    }

    private var stagingSnapshotSection: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DockWalkTheme.sectionSpacing) {
                if let putawaySuccessMessage {
                    StatusChip(label: putawaySuccessMessage, tone: .success)
                }

                InventoryStagingSnapshotView(
                    sections: stagingSections,
                    onSelectCard: { card in
                        pendingPutawayCard = card
                        putawayError = nil
                        showPutawaySheet = true
                    }
                )
            }
            .padding(DockWalkTheme.screenPadding)
        }
    }

    private func handleScannedCode(_ value: String) {
        showScanner = false
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if let card = PutawayCardResolver.resolve(
            upc: trimmed,
            inboundSession: inboundSession,
            catalog: inventoryCatalog,
            completionStore: completionStore
        ) {
            pendingPutawayCard = card
            putawayError = nil
            showPutawaySheet = true
            return
        }

        viewModel.searchQuery = trimmed
        viewModel.refreshFromCatalog()
    }

    private func handleFloatingScanRequestIfNeeded() {
        let token = inventoryScannerCoordinator.openScannerToken
        guard token != lastHandledScanToken else { return }
        lastHandledScanToken = token
        guard scannerPreferences.isScannerActive else { return }
        showScanner = true
    }

    private func applyPutaway(to bin: String) async {
        guard let card = pendingPutawayCard else { return }
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
            pendingPutawayCard = nil
            putawayError = nil
            putawaySuccessMessage = "Put away to \(bin.trimmingCharacters(in: .whitespacesAndNewlines))"
        case .failure(let error):
            putawayError = error.localizedDescription
            showPutawaySheet = true
        }
    }

    private var searchField: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(DockWalkTheme.textSecondary)
            TextField("Search SKU, part, bin, or item", text: $viewModel.searchQuery)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            if !viewModel.searchQuery.isEmpty {
                Button {
                    viewModel.searchQuery = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(DockWalkTheme.textSecondary)
                }
            }
        }
        .padding(14)
        .background(DockWalkTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DockWalkTheme.cornerRadius))
    }

    private var itemsSection: some View {
        ScrollView {
            if viewModel.isScannedCodeNotFound {
                upcNotFoundState
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.filteredItems) { item in
                        itemCard(item)
                    }
                }
                .padding(DockWalkTheme.screenPadding)
            }
        }
    }

    private var upcNotFoundState: some View {
        VStack(spacing: 16) {
            Image(systemName: "barcode.viewfinder")
                .font(.system(size: 48))
                .foregroundStyle(DockWalkTheme.textSecondary.opacity(0.5))
            Text("UPC not found")
                .font(DockWalkTheme.headlineFont)
            Text(viewModel.searchQuery)
                .font(.system(.body, design: .monospaced).weight(.semibold))
            Text("No inventory matches this code.")
                .font(DockWalkTheme.captionFont)
                .foregroundStyle(DockWalkTheme.textSecondary)
                .multilineTextAlignment(.center)
            PrimaryActionButton(title: "Add inventory?", systemImage: "plus.rectangle.on.rectangle") {
                showAddInventory = true
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(DockWalkTheme.screenPadding)
    }

    private func itemCard(_ item: InventoryItem) -> some View {
        Button {
            selectedItem = item
        } label: {
            SectionCard {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(item.description)
                            .font(DockWalkTheme.headlineFont)
                            .foregroundStyle(DockWalkTheme.textPrimary)

                        Text("SKU \(item.sku)")
                            .font(DockWalkTheme.captionFont)
                            .foregroundStyle(DockWalkTheme.textSecondary)

                        HStack(spacing: 12) {
                            Text("Qty \(item.onHand)")
                                .font(DockWalkTheme.bodyFont)
                            Text("·")
                                .foregroundStyle(DockWalkTheme.textSecondary)
                            Text("Bin \(item.location)")
                                .font(DockWalkTheme.bodyFont)
                            Text("·")
                                .foregroundStyle(DockWalkTheme.textSecondary)
                            if item.reserved > 0 {
                                StatusChip(label: "Reserved", tone: .warning)
                            } else {
                                StatusChip(label: "Available", tone: .success)
                            }
                        }
                        .font(DockWalkTheme.captionFont)
                        .foregroundStyle(DockWalkTheme.textSecondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(DockWalkTheme.textSecondary)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

/// Staging snapshot grouped by location — default Inventory home when search is empty.
struct InventoryStagingSnapshotView: View {
    let sections: [PutawayCardQueueBuilder.StagingLocationSection]
    let onSelectCard: (PutawayUPCCard) -> Void

    var body: some View {
        if sections.isEmpty {
            VStack(spacing: 16) {
                Image(systemName: "shippingbox")
                    .font(.system(size: 48))
                    .foregroundStyle(DockWalkTheme.textSecondary.opacity(0.5))
                Text("Nothing at staging")
                    .font(DockWalkTheme.headlineFont)
                Text("Receive on a load first, then put away from here.")
                    .font(DockWalkTheme.captionFont)
                    .foregroundStyle(DockWalkTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 32)
        } else {
            VStack(alignment: .leading, spacing: DockWalkTheme.sectionSpacing) {
                Text("At staging")
                    .font(DockWalkTheme.headlineFont)

                ForEach(sections) { section in
                    VStack(alignment: .leading, spacing: 10) {
                        Text(section.locationCode)
                            .font(DockWalkTheme.captionFont.weight(.semibold))
                            .foregroundStyle(DockWalkTheme.textSecondary)

                        SectionCard {
                            VStack(spacing: 8) {
                                ForEach(section.cards) { card in
                                    PutawayStagingBubbleRow(card: card) {
                                        onSelectCard(card)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

/// Load-scoped staging view linked from inbound load detail.
struct InventoryLoadStagingView: View {
    @Environment(AppEnvironment.self) private var environment
    @Environment(InboundSessionStore.self) private var inboundSession
    @Environment(PutawayCompletionStore.self) private var completionStore
    @Environment(FacilityConfigStore.self) private var facilityConfig
    @Environment(InventoryCatalogStore.self) private var inventoryCatalog
    @Environment(OfflineSyncStore.self) private var syncStore
    @Environment(ScannerPreferencesStore.self) private var scannerPreferences

    let loadId: String
    let loadTitle: String

    @State private var pendingPutawayCard: PutawayUPCCard?
    @State private var showPutawaySheet = false
    @State private var showBinScanner = false
    @State private var putawayError: String?
    @State private var putawaySuccessMessage: String?

    private var stagingSections: [PutawayCardQueueBuilder.StagingLocationSection] {
        PutawayCardQueueBuilder.groupedPendingCards(
            inboundShipmentId: loadId,
            inboundSession: inboundSession,
            completionStore: completionStore,
            facilityConfig: facilityConfig
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DockWalkTheme.sectionSpacing) {
                if let putawaySuccessMessage {
                    StatusChip(label: putawaySuccessMessage, tone: .success)
                }

                InventoryStagingSnapshotView(
                    sections: stagingSections,
                    onSelectCard: { card in
                        pendingPutawayCard = card
                        putawayError = nil
                        showPutawaySheet = true
                    }
                )
            }
            .padding(DockWalkTheme.screenPadding)
        }
        .background(DockWalkTheme.background)
        .navigationTitle(loadTitle)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showPutawaySheet) {
            if let pendingPutawayCard {
                InventoryPutawaySheet(
                    card: pendingPutawayCard,
                    errorMessage: putawayError,
                    onPutAway: {
                        putawayError = nil
                        showPutawaySheet = false
                        showBinScanner = true
                    },
                    onDismiss: {
                        self.pendingPutawayCard = nil
                        putawayError = nil
                    }
                )
            }
        }
        .sheet(isPresented: $showBinScanner) {
            BarcodeScannerSheet(title: "Scan storage bin") { result in
                showBinScanner = false
                Task { await applyPutaway(to: result.value) }
            }
        }
        .dismissScannerSheetWhenInactive(scannerPreferences, isPresented: $showBinScanner)
    }

    private func applyPutaway(to bin: String) async {
        guard let card = pendingPutawayCard else { return }
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
            pendingPutawayCard = nil
            putawayError = nil
            putawaySuccessMessage = "Put away to \(bin.trimmingCharacters(in: .whitespacesAndNewlines))"
        case .failure(let error):
            putawayError = error.localizedDescription
            showPutawaySheet = true
        }
    }
}

struct PutawayStagingBubbleRow: View {
    let card: PutawayUPCCard
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(card.upc)
                        .font(.system(.body, design: .monospaced).weight(.semibold))
                        .foregroundStyle(DockWalkTheme.textPrimary)
                        .lineLimit(1)

                    Text(card.description)
                        .font(DockWalkTheme.captionFont)
                        .foregroundStyle(DockWalkTheme.textSecondary)
                        .lineLimit(1)

                    if let sku = card.secondarySKULabel {
                        Text(sku)
                            .font(DockWalkTheme.captionFont)
                            .foregroundStyle(DockWalkTheme.textSecondary)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 6) {
                    Text(card.quantityDisplay)
                        .font(DockWalkTheme.captionFont.weight(.medium))
                        .foregroundStyle(DockWalkTheme.textSecondary)
                    StatusChip(label: "At staging", tone: .neutral)
                }

                Image(systemName: "chevron.right")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(DockWalkTheme.textSecondary)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }
}

struct InventoryPutawaySheet: View {
    @Environment(\.dismiss) private var dismiss

    let card: PutawayUPCCard
    let errorMessage: String?
    let onPutAway: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: DockWalkTheme.sectionSpacing) {
                SectionCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("At \(card.fromLocationCode.isEmpty ? "staging" : card.fromLocationCode)")
                            .font(DockWalkTheme.bodyFont.weight(.semibold))
                        Text(card.upc)
                            .font(.system(.body, design: .monospaced))
                        Text(card.quantityDisplay)
                            .font(DockWalkTheme.captionFont)
                            .foregroundStyle(DockWalkTheme.textSecondary)
                        Text("Scan a storage bin to put this line away.")
                            .font(DockWalkTheme.captionFont)
                            .foregroundStyle(DockWalkTheme.textSecondary)
                    }
                }

                PrimaryActionButton(title: "Put away", systemImage: "barcode.viewfinder", action: onPutAway)

                if let errorMessage {
                    Text(errorMessage)
                        .font(DockWalkTheme.captionFont)
                        .foregroundStyle(DockWalkTheme.warning)
                }

                Spacer()
            }
            .padding(DockWalkTheme.screenPadding)
            .background(DockWalkTheme.background)
            .navigationTitle("Put away")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        onDismiss()
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    InventoryHomeView()
        .environment(AppEnvironment.shared)
        .environment(ScannerPreferencesStore.shared)
        .environment(InventoryScannerCoordinator.shared)
        .environment(InventoryCatalogStore.shared)
        .environment(InboundSessionStore.shared)
        .environment(PutawayCompletionStore.shared)
        .environment(FacilityConfigStore.shared)
        .environment(OfflineSyncStore.shared)
}
