import SwiftUI

/// Shipping load work mode — scan staged product, confirm loaded items, complete shipment.
struct ShippingLoadDetailView: View {
    @Environment(AppEnvironment.self) private var environment
    @Environment(OfflineSyncStore.self) private var syncStore
    @Environment(ScannerPreferencesStore.self) private var scannerPreferences

    @State private var currentOrder: OutboundOrder
    @State private var stagedLines: [OutboundLine] = []
    @State private var showScanConfirm = false
    @State private var showException = false
    @State private var showScanner = false
    @State private var pendingScanCode = ""
    @State private var isSubmittingTransition = false
    @State private var bannerMessage: String?
    @State private var bannerTone: StatusChip.Tone = .neutral

    init(order: OutboundOrder) {
        _currentOrder = State(initialValue: order)
    }

    private var shipmentId: String {
        currentOrder.orderNumber
    }

    private var loadedCount: Double {
        stagedLines.reduce(0) { $0 + $1.loadedQty }
    }

    private var orderedCount: Double {
        stagedLines.reduce(0) { $0 + $1.orderedQty }
    }

    private var loadedPercent: Int {
        guard orderedCount > 0 else { return 0 }
        let value = Int((loadedCount / orderedCount) * 100)
        return min(max(value, 0), 100)
    }

    private var statusTransitionAction: (title: String, target: OutboundOrderStatus)? {
        switch currentOrder.status {
        case .staged:
            return ("Start loading", .loading)
        case .loading:
            return ("Mark shipped", .shipped)
        default:
            return nil
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DockWalkTheme.sectionSpacing) {
                ScannerLockChip(mode: .shipment(shipmentId: shipmentId))

                loadHeader

                progressRow

                if let bannerMessage {
                    StatusChip(label: bannerMessage, tone: bannerTone)
                }

                if let action = statusTransitionAction {
                    PrimaryActionButton(
                        title: action.title,
                        systemImage: action.target == .shipped ? "checkmark.seal.fill" : "truck.box"
                    ) {
                        Task { await transitionOrder(to: action.target, reason: action.title, lineTransitions: []) }
                    }
                    .disabled(isSubmittingTransition)
                }

                PrimaryActionButton(title: "Scan staged product", systemImage: "barcode.viewfinder") {
                    if scannerPreferences.isScannerActive {
                        showScanner = true
                    } else {
                        showScanConfirm = true
                    }
                }
                .disabled(isSubmittingTransition)

                secondaryActions

                stagedLinesSection
            }
            .padding(DockWalkTheme.screenPadding)
        }
        .background(DockWalkTheme.background)
        .navigationTitle(shipmentId)
        .navigationBarTitleDisplayMode(.inline)
        .task(id: environment.configRevision) {
            await refreshShippingDetail()
        }
        .sheet(isPresented: $showScanConfirm) {
            ScanConfirmSheet(payload: ScanConfirmPayload.placeholder)
        }
        .sheet(isPresented: $showException) {
            ExceptionMarkingSheet()
        }
        .sheet(isPresented: $showScanner) {
            BarcodeScannerSheet(title: "Scan staged product") { result in
                pendingScanCode = result.value
                showScanner = false
                Task { await handleScannedUPC(result.value) }
            }
        }
        .dismissScannerSheetWhenInactive(scannerPreferences, isPresented: $showScanner)
    }

    private var loadHeader: some View {
        LoadCardView(
            model: LoadCardModel(
                id: currentOrder.id,
                title: currentOrder.orderNumber,
                subtitle: currentOrder.customer,
                statusLabel: currentOrder.status.displayName,
                statusTone: currentOrder.status.chipTone,
                metaRows: [
                    "Door: \(currentOrder.door.isEmpty ? "TBD" : currentOrder.door)",
                    "Lines: \(currentOrder.lineCount)",
                ]
            )
        )
    }

    private var progressRow: some View {
        SectionCard {
            HStack {
                Text("\(Int(loadedCount)) / \(max(Int(orderedCount), currentOrder.cartonCount)) items loaded")
                    .font(.system(.caption, design: .monospaced).weight(.semibold))
                Spacer()
                Text("\(loadedPercent)%")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(DockWalkTheme.textSecondary)
            }
        }
    }

    private var secondaryActions: some View {
        HStack(spacing: 8) {
            secondaryButton(title: "Shipment details", systemImage: "list.bullet") {}
            secondaryButton(title: "Mark missing", systemImage: "exclamationmark.triangle") {
                showException = true
            }
            secondaryButton(title: "Refresh", systemImage: "arrow.clockwise") {
                Task { await refreshShippingDetail() }
            }
        }
    }

    private var stagedLinesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Staged items · \(stagedLines.count)")
                .font(DockWalkTheme.headlineFont)

            SectionCard {
                if stagedLines.isEmpty {
                    Text("No staged lines available.")
                        .font(DockWalkTheme.bodyFont)
                        .foregroundStyle(DockWalkTheme.textSecondary)
                } else {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(stagedLines) { line in
                            UPCCardView(
                                model: UPCLineModel(
                                    id: line.id,
                                    upc: line.upc.isEmpty ? "—" : line.upc,
                                    sku: line.sku,
                                    quantityLabel: "\(Int(line.loadedQty)) / \(Int(line.orderedQty)) \(line.uom.uppercased())",
                                    locationLabel: line.location ?? "STAGE",
                                    statusLabel: line.status.replacingOccurrences(of: "_", with: " ").capitalized,
                                    statusTone: line.loadedQty >= line.orderedQty ? .success : .neutral
                                )
                            )
                        }
                    }
                }
            }
        }
    }

    private func secondaryButton(title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Image(systemName: systemImage)
                Text(title)
                    .font(.system(size: 10.5, weight: .semibold))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 11)
            .foregroundStyle(DockWalkTheme.textPrimary)
            .background(DockWalkTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    private func refreshShippingDetail() async {
        let client = environment.makeAPIClient()
        do {
            let detail = try await client.fetchOutboundOrder(orderId: currentOrder.id, orgId: environment.orgId)
            let lines = try await client.fetchOutboundOrderLines(orderId: currentOrder.id, orgId: environment.orgId)
            currentOrder = OutboundAPIMapping.mapOrder(detail.item)
            stagedLines = lines.items.map(OutboundAPIMapping.mapLine)
        } catch {
            bannerMessage = "Using local shipping data until API reconnects."
            bannerTone = .warning
        }
    }

    private func handleScannedUPC(_ upc: String) async {
        guard !upc.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        guard let line = stagedLines.first(where: { $0.upc == upc }) else {
            bannerMessage = "UPC \(upc) is not staged for this load."
            bannerTone = .danger
            return
        }
        let nextStatus: OutboundOrderStatus = currentOrder.status == .staged ? .loading : currentOrder.status
        let lineTransition = OutboundLineTransitionRequest(
            lineId: line.id,
            upc: upc,
            quantityLoaded: 1,
            allowOverscan: false
        )
        await transitionOrder(
            to: nextStatus,
            reason: "Load scan \(upc)",
            lineTransitions: [lineTransition]
        )
    }

    private func transitionOrder(
        to nextStatus: OutboundOrderStatus,
        reason: String,
        lineTransitions: [OutboundLineTransitionRequest]
    ) async {
        guard !isSubmittingTransition else { return }
        isSubmittingTransition = true
        defer { isSubmittingTransition = false }

        let payload = OutboundOrderTransitionRequest(
            orgId: environment.orgId,
            toStatus: nextStatus.rawValue,
            idempotencyKey: "ios-outbound-\(UUID().uuidString.lowercased())",
            facilityId: environment.facilityId,
            deviceId: ReceivingEventBuilder.deviceId,
            notes: reason,
            metadata: nil,
            lineTransitions: lineTransitions
        )

        let client = environment.makeAPIClient()
        do {
            let response = try await client.transitionOutboundOrder(orderId: currentOrder.id, body: payload)
            if let updated = response.item?.order {
                currentOrder = OutboundAPIMapping.mapOrder(updated)
            }
            bannerMessage = response.idempotent == true
                ? "Transition already recorded."
                : "Transition submitted."
            bannerTone = .success
            await refreshShippingDetail()
        } catch {
            if APIClientErrorClassifier.shouldQueueOffline(for: error) {
                syncStore.enqueueOutboundTransition(
                    orderId: currentOrder.id,
                    payload: payload,
                    summary: reason
                )
                bannerMessage = "Queued for sync while offline."
                bannerTone = .warning
            } else {
                bannerMessage = "Transition failed. Refresh and retry."
                bannerTone = .danger
            }
        }
    }
}

#Preview {
    NavigationStack {
        ShippingLoadDetailView(
            order: OutboundOrder(
                id: "out-ship",
                orderNumber: "S-55120",
                customer: "Midwest Supply",
                door: "Door 2",
                status: .staged,
                lineCount: 14,
                cartonCount: 14,
                priority: .urgent,
                shipDate: Date(),
                assignedTo: nil
            )
        )
    }
    .environment(AppEnvironment.shared)
    .environment(OfflineSyncStore.shared)
    .environment(ScannerPreferencesStore.shared)
}
