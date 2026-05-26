import SwiftUI

/// Receive work mode — scan and capture inventory onto the load (no legacy shipment-lines API).
struct ShipmentDetailView: View {
    @Environment(AppEnvironment.self) private var environment
    @Environment(ReceiveScannerCoordinator.self) private var receiveScannerCoordinator
    @Environment(ScannerPreferencesStore.self) private var scannerPreferences
    @Binding var load: ReceivingAppointment
    let appointmentsViewModel: AppointmentsViewModel

    @State private var viewModel: ShipmentDetailViewModel
    @State private var showLineScanner = false
    @State private var showEditSheet = false
    @State private var editingItem: ReceiveInventoryDraft?
    @State private var pendingScanCode: String?
    @State private var lastHandledScanToken = 0
    @State private var skuPendingClone: String?
    @State private var showAddAnotherUPCAlert = false

    init(
        load: Binding<ReceivingAppointment>,
        appointmentsViewModel: AppointmentsViewModel,
        environment: AppEnvironment = .shared
    ) {
        _load = load
        self.appointmentsViewModel = appointmentsViewModel
        _viewModel = State(initialValue: ShipmentDetailViewModel(loadId: load.wrappedValue.id, environment: environment))
    }

    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DockWalkTheme.sectionSpacing) {
                    ScannerLockChip(mode: .load(loadId: load.poNumber))
                    hubSnapshot
                    inventoryBubbles
                }
                .padding(DockWalkTheme.screenPadding)
            }

            if viewModel.loadPhase == .loading {
                LoadStateView(phase: .loading)
                    .background(.ultraThinMaterial)
            }
        }
        .background(DockWalkTheme.background)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 2) {
                    Text(load.poNumber)
                        .font(.headline)
                    Text(load.carrier)
                        .font(.caption)
                        .foregroundStyle(DockWalkTheme.textSecondary)
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") {
                    showEditSheet = true
                }
            }
        }
        .sheet(isPresented: $showEditSheet) {
            EditLoadView(load: $load, viewModel: appointmentsViewModel)
        }
        .task(id: environment.configRevision) {
            await viewModel.load()
        }
        .onAppear {
            receiveScannerCoordinator.setReceiveHubActive(true)
            handleFloatingScanRequestIfNeeded()
        }
        .onDisappear {
            receiveScannerCoordinator.setReceiveHubActive(false)
        }
        .onChange(of: receiveScannerCoordinator.openScannerToken) { _, _ in
            handleFloatingScanRequestIfNeeded()
        }
        .sheet(isPresented: $showLineScanner) {
            BarcodeScannerSheet(
                title: "Scan UPC",
                applyStyle: .direct,
                applyButtonTitle: "Use this UPC",
                manualEntryPlaceholder: "UPC"
            ) { result in
                pendingScanCode = result.value
                showLineScanner = false
            }
        }
        .onChange(of: showLineScanner) { _, isShowing in
            guard !isShowing else { return }
            if let code = pendingScanCode {
                if let sku = skuPendingClone {
                    presentReceiveEntryCloningSKU(sku: sku, upc: code)
                } else {
                    presentReceiveEntry(for: code)
                }
                pendingScanCode = nil
                skuPendingClone = nil
            } else {
                skuPendingClone = nil
            }
        }
        .alert("Add another UPC for this SKU?", isPresented: $showAddAnotherUPCAlert) {
            Button("Yes") {
                showLineScanner = true
            }
            Button("Cancel", role: .cancel) {
                skuPendingClone = nil
            }
        }
        .fullScreenCover(item: $editingItem) { item in
            if let binding = binding(for: item) {
                InventoryEntryView(
                    item: binding,
                    loadId: load.id,
                    onSave: {
                        let success = viewModel.saveItem(id: item.id)
                        if success {
                            syncReceivedLineCount()
                        }
                        return success
                    },
                    onCancel: {
                        if !item.isSaved {
                            viewModel.removeItem(id: item.id)
                        }
                    }
                )
            }
        }
    }

    @ViewBuilder
    private var hubSnapshot: some View {
        if viewModel.loadPhase == .loaded {
            ReceiveHubSnapshot(
                totalUPCs: viewModel.totalUPCs,
                totalCases: viewModel.totalCases,
                totalEaches: viewModel.totalEaches,
                uniqueSKUs: viewModel.uniqueSKUs,
                skuGroups: viewModel.skuGroups,
                onAddAnotherUPC: { sku in
                    skuPendingClone = sku
                    showAddAnotherUPCAlert = true
                }
            )
        }
    }
    
    @ViewBuilder
    private var inventoryBubbles: some View {
        if viewModel.loadPhase == .loaded {
            VStack(alignment: .leading, spacing: 12) {
                Text("Received Items")
                    .font(DockWalkTheme.headlineFont)
                
                if viewModel.savedItemCount == 0 {
                    Text("Tap the scanner button to add inventory items.")
                        .font(DockWalkTheme.captionFont)
                        .foregroundStyle(DockWalkTheme.textSecondary)
                        .padding(.vertical, 8)
                } else {
                    ForEach(viewModel.receivedItems.filter(\.isSaved)) { item in
                        InventoryBubbleRow(item: item) {
                            editingItem = item
                        }
                    }
                }
            }
        }
    }

    private func handleFloatingScanRequestIfNeeded() {
        let token = receiveScannerCoordinator.openScannerToken
        guard token > lastHandledScanToken else { return }
        lastHandledScanToken = token
        if scannerPreferences.isScannerActive {
            showLineScanner = true
        } else {
            presentReceiveEntry(for: "SCAN-\(Int.random(in: 1000...9999))")
        }
    }

    private func presentReceiveEntry(for code: String) {
        skuPendingClone = nil
        let newItem = ReceiveInventoryDraft.fromScan(code)
        viewModel.addItem(newItem)
        editingItem = newItem
    }

    private func presentReceiveEntryCloningSKU(sku: String, upc: String) {
        guard let template = viewModel.templateItem(forSKU: sku) else {
            presentReceiveEntry(for: upc)
            return
        }
        let newItem = ReceiveInventoryDraft.cloningSKU(from: template, upc: upc)
        viewModel.addItem(newItem)
        editingItem = newItem
    }

    private func binding(for item: ReceiveInventoryDraft) -> Binding<ReceiveInventoryDraft>? {
        Binding(
            get: {
                viewModel.receivedItems.first(where: { $0.id == item.id }) ?? item
            },
            set: { viewModel.updateItem($0) }
        )
    }

    private func syncReceivedLineCount() {
        let count = viewModel.savedItemCount
        guard load.receivedLineCount != count else { return }
        let updated = ReceivingAppointment(
            id: load.id,
            carrier: load.carrier,
            dock: load.dock,
            scheduledAt: load.scheduledAt,
            status: load.status,
            poNumber: load.poNumber,
            palletCount: load.palletCount,
            vendor: load.vendor,
            expectedLineCount: load.expectedLineCount,
            receivedLineCount: count,
            doorNumber: load.doorNumber
        )
        load = updated
        appointmentsViewModel.updateLoad(updated)
    }
}

#Preview {
    NavigationStack {
        ShipmentDetailView(
            load: .constant(
                ReceivingAppointment(
                    id: "T-4401",
                    carrier: "Old Dominion",
                    dock: "D-07",
                    scheduledAt: Date(),
                    status: .receiving,
                    poNumber: "T-4401",
                    palletCount: 22,
                    vendor: "Midwest Parts",
                    expectedLineCount: 0,
                    receivedLineCount: 0,
                    doorNumber: "D-07"
                )
            ),
            appointmentsViewModel: AppointmentsViewModel()
        )
    }
    .environment(AppEnvironment.shared)
    .environment(InboundSessionStore.shared)
    .environment(InventoryCatalogStore.shared)
    .environment(ReceiveScannerCoordinator.shared)
    .environment(ScannerPreferencesStore.shared)
}
