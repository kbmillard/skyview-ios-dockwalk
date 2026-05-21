import SwiftUI

/// Receive work mode — scan and capture inventory onto the load (no legacy shipment-lines API).
struct ShipmentDetailView: View {
    @Environment(AppEnvironment.self) private var environment
    @Environment(ScannerPreferencesStore.self) private var scannerPreferences
    @Binding var load: ReceivingAppointment
    let appointmentsViewModel: AppointmentsViewModel

    @Bindable var viewModel: ShipmentDetailViewModel
    @State private var showLineScanner = false
    @State private var showDockDoors = false

    init(
        load: Binding<ReceivingAppointment>,
        appointmentsViewModel: AppointmentsViewModel,
        environment: AppEnvironment = .shared
    ) {
        _load = load
        self.appointmentsViewModel = appointmentsViewModel
        viewModel = ShipmentDetailViewModel(
            load: load.wrappedValue,
            environment: environment
        )
    }

    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DockWalkTheme.sectionSpacing) {
                    ScannerLockChip(mode: .load(loadId: load.poNumber))

                    loadHeader

                    PrimaryActionButton(title: "Scan Item", systemImage: "barcode.viewfinder") {
                        if scannerPreferences.isScannerActive {
                            showLineScanner = true
                        } else {
                            viewModel.addFromScan("SCAN-\(Int.random(in: 1000...9999))")
                        }
                    }

                    Button {
                        viewModel.addEmptyCard()
                    } label: {
                        Label("Add inventory card", systemImage: "plus.rectangle.on.rectangle")
                            .font(DockWalkTheme.captionFont.weight(.semibold))
                    }
                    .foregroundStyle(DockWalkTheme.accent)

                    Button { showDockDoors = true } label: {
                        Label("Change door", systemImage: "door.left.hand.open")
                            .font(DockWalkTheme.captionFont.weight(.semibold))
                    }
                    .foregroundStyle(DockWalkTheme.accent)

                    receivedItemsSection
                }
                .padding(DockWalkTheme.screenPadding)
            }

            if viewModel.loadPhase == .loading {
                LoadStateView(phase: .loading)
                    .background(.ultraThinMaterial)
            }
        }
        .background(DockWalkTheme.background)
        .navigationTitle(load.poNumber)
        .navigationBarTitleDisplayMode(.inline)
        .task(id: environment.configRevision) {
            promoteToReceivingIfNeeded()
            await viewModel.load()
        }
        .sheet(isPresented: $showLineScanner) {
            BarcodeScannerSheet(title: "Scan item") { result in
                viewModel.addFromScan(result.value)
            }
        }
        .sheet(isPresented: $showDockDoors) {
            DockDoorSelectorSheet(
                loadReference: load.poNumber,
                doorOptions: appointmentsViewModel.doorPickerOptions(
                    forLoadId: load.id,
                    currentSelection: load.assignedDoorNumber
                ),
                initialSelection: load.assignedDoorNumber,
                allowsClear: false
            ) { doorId in
                if let doorId {
                    applyDoor(doorId)
                }
            }
        }
    }

    private var loadHeader: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 8) {
                Text(load.carrier)
                    .font(DockWalkTheme.headlineFont)
                StatusChip(label: load.status.displayName, tone: load.status.chipTone)
                Text("Receive work mode — add inventory cards for each SKU you put away.")
                    .font(DockWalkTheme.captionFont)
                    .foregroundStyle(DockWalkTheme.textSecondary)
            }
        }
    }

    @ViewBuilder
    private var receivedItemsSection: some View {
        switch viewModel.loadPhase {
        case .loaded:
            VStack(alignment: .leading, spacing: 12) {
                Text("Received inventory")
                    .font(DockWalkTheme.headlineFont)

                if viewModel.receivedItems.isEmpty {
                    Text("Scan a barcode or tap Add inventory card to record what you received.")
                        .font(DockWalkTheme.captionFont)
                        .foregroundStyle(DockWalkTheme.textSecondary)
                        .padding(.vertical, 8)
                } else {
                    ForEach(Array(viewModel.receivedItems.enumerated()), id: \.element.id) { index, item in
                        if let binding = binding(for: item) {
                            ReceiveInventoryCardView(
                                item: binding,
                                index: index + 1,
                                onRemove: { viewModel.removeItem(id: item.id) }
                            )
                        }
                    }
                }
            }
        case .idle, .loading:
            EmptyView()
        case .empty, .error:
            EmptyView()
        }
    }

    private func binding(for item: ReceiveInventoryDraft) -> Binding<ReceiveInventoryDraft>? {
        Binding(
            get: {
                viewModel.receivedItems.first(where: { $0.id == item.id }) ?? item
            },
            set: { viewModel.updateItem($0) }
        )
    }

    private func promoteToReceivingIfNeeded() {
        guard load.status != .receiving else { return }
        let updated = copyLoad(status: .receiving)
        load = updated
        appointmentsViewModel.updateLoad(updated)
    }

    private func applyDoor(_ doorId: String) {
        let updated = ReceivingAppointment(
            id: load.id,
            carrier: load.carrier,
            dock: doorId,
            scheduledAt: load.scheduledAt,
            status: load.status,
            poNumber: load.poNumber,
            palletCount: load.palletCount,
            vendor: load.vendor,
            expectedLineCount: load.expectedLineCount,
            receivedLineCount: load.receivedLineCount,
            doorNumber: doorId
        )
        load = updated
        appointmentsViewModel.updateLoad(updated)
    }

    private func copyLoad(status: InboundLoadStatus) -> ReceivingAppointment {
        ReceivingAppointment(
            id: load.id,
            carrier: load.carrier,
            dock: load.dock,
            scheduledAt: load.scheduledAt,
            status: status,
            poNumber: load.poNumber,
            palletCount: load.palletCount,
            vendor: load.vendor,
            expectedLineCount: load.expectedLineCount,
            receivedLineCount: load.receivedLineCount,
            doorNumber: load.doorNumber
        )
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
    .environment(ScannerPreferencesStore.shared)
}
