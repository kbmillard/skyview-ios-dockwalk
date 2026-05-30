import SwiftUI

struct LoadDetailView: View {
    @Environment(InboundSessionStore.self) private var inboundSession
    @Binding var load: ReceivingAppointment
    let viewModel: AppointmentsViewModel
    let environment: AppEnvironment

    @State private var showEditSheet = false
    @State private var showDoorSelector = false
    @State private var syncNotice: String?
    private var canEditLoad: Bool {
        switch load.status {
        case .scheduled, .checkedIn, .staged, .receiving:
            return true
        case .complete, .cancelled:
            return false
        }
    }

    private var savedReceivedItems: [ReceiveInventoryDraft] {
        let _ = inboundSession.receivedInventoryRevision
        return inboundSession.receivedItems(for: load.id).filter(\.isSaved)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DockWalkTheme.sectionSpacing) {
                loadSummaryCard
                if let syncNotice {
                    StatusChip(label: syncNotice, tone: .warning)
                }
                actionButtons
                receivedSummarySection
            }
            .padding(DockWalkTheme.screenPadding)
        }
        .background(DockWalkTheme.background)
        .navigationTitle(load.poNumber)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if canEditLoad {
                ToolbarItem(placement: .primaryAction) {
                    Button("Edit") {
                        showEditSheet = true
                    }
                }
            }
        }
        .sheet(isPresented: $showEditSheet) {
            EditLoadView(load: $load, viewModel: viewModel)
        }
        .onAppear {
            let _ = inboundSession.receivedInventoryRevision
        }
        .sheet(isPresented: $showDoorSelector) {
            DockDoorSelectorSheet(
                loadReference: load.poNumber,
                doorOptions: viewModel.doorPickerOptions(
                    forLoadId: load.id,
                    currentSelection: load.assignedDoorNumber
                ),
                initialSelection: load.assignedDoorNumber,
                allowsClear: false
            ) { doorId in
                if let doorId {
                    assignDoor(doorId)
                }
            }
        }
    }

    private func assignDoor(_ doorId: String) {
        Task {
            await applyDoor(doorId, status: .staged)
        }
    }

    private func applyDoor(_ doorId: String?, status: InboundLoadStatus) async {
        let updated = ReceivingAppointment(
            id: load.id,
            carrier: load.carrier,
            dock: doorId ?? "",
            scheduledAt: load.scheduledAt,
            status: status,
            poNumber: load.poNumber,
            palletCount: load.palletCount,
            vendor: load.vendor,
            expectedLineCount: load.expectedLineCount,
            receivedLineCount: load.receivedLineCount,
            doorNumber: doorId
        )
        load = updated
        viewModel.updateLoad(updated)
        let synced = await viewModel.syncLoadToAPI(updated)
        if !synced {
            syncNotice = "Saved locally. Will sync when API is reachable."
        } else {
            syncNotice = nil
        }
    }

    private func checkIn() {
        Task {
            await applyDoor(load.assignedDoorNumber, status: .checkedIn)
        }
    }

    private func ensureReceivingStatus() {
        guard load.status != .receiving else { return }
        Task {
            let updated = copyLoad(status: .receiving)
            load = updated
            viewModel.updateLoad(updated)
            let synced = await viewModel.syncLoadToAPI(updated)
            if !synced {
                syncNotice = "Receiving started locally. Sync queued for reconnect."
            } else {
                syncNotice = nil
            }
        }
    }

    private func copyLoad(status: InboundLoadStatus, receivedLineCount: Int? = nil) -> ReceivingAppointment {
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
            receivedLineCount: receivedLineCount ?? load.receivedLineCount,
            doorNumber: load.doorNumber
        )
    }

    private var loadSummaryCard: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(load.carrier)
                        .font(DockWalkTheme.headlineFont)
                    Spacer()
                    StatusChip(label: load.status.displayName, tone: load.status.chipTone)
                }

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    summaryRow(label: "PO Number", systemImage: "doc.text", value: load.poNumber)

                    if let vendor = load.vendor, !vendor.isEmpty {
                        summaryRow(label: "Vendor", systemImage: "building.2", value: vendor)
                    }

                    summaryRow(
                        label: "Scheduled",
                        systemImage: "clock",
                        value: load.scheduledAt.formatted(date: .abbreviated, time: .shortened)
                    )

                    summaryRow(
                        label: "Door",
                        systemImage: "door.left.hand.open",
                        value: load.doorAssignmentLabel
                    )

                    summaryRow(label: "Pallets", systemImage: "square.stack.3d.up", value: "\(load.palletCount)")
                }
            }
        }
    }

    private func summaryRow(label: String, systemImage: String, value: String) -> some View {
        HStack {
            Label(label, systemImage: systemImage)
                .font(DockWalkTheme.captionFont)
                .foregroundStyle(DockWalkTheme.textSecondary)
            Spacer()
            Text(value)
                .font(DockWalkTheme.bodyFont)
                .foregroundStyle(DockWalkTheme.textPrimary)
                .multilineTextAlignment(.trailing)
        }
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            switch load.status {
            case .scheduled:
                PrimaryActionButton(title: "Check In", systemImage: "checkmark.circle", style: .primary) {
                    checkIn()
                }
                PrimaryActionButton(title: "Reschedule", systemImage: "calendar", style: .secondary) {
                    showEditSheet = true
                }

            case .checkedIn:
                PrimaryActionButton(title: "Assign Door", systemImage: "door.left.hand.open", style: .primary) {
                    showDoorSelector = true
                }

            case .staged:
                NavigationLink {
                    ShipmentDetailView(
                        load: $load,
                        appointmentsViewModel: viewModel,
                        environment: environment
                    )
                    .onAppear { ensureReceivingStatus() }
                } label: {
                    actionLinkLabel(title: "Start Receiving", systemImage: "arrow.down.doc", isPrimary: true)
                }
                .buttonStyle(.plain)

            case .receiving:
                NavigationLink {
                    ShipmentDetailView(
                        load: $load,
                        appointmentsViewModel: viewModel,
                        environment: environment
                    )
                } label: {
                    actionLinkLabel(title: "Resume Receiving", systemImage: "arrow.down.doc", isPrimary: true)
                }
                .buttonStyle(.plain)

            case .complete:
                NavigationLink {
                    InventoryLoadStagingView(loadId: load.id, loadTitle: load.poNumber)
                } label: {
                    actionLinkLabel(title: "Putaway for this load", systemImage: "arrow.down.to.line.compact", isPrimary: true)
                }
                .buttonStyle(.plain)
                PrimaryActionButton(title: "View Receipt", systemImage: "doc.text", style: .secondary) {
                    // View receipt action
                }

            case .cancelled:
                PrimaryActionButton(title: "Reopen Load", systemImage: "arrow.counterclockwise", style: .secondary) {
                    // Reopen action
                }
            }
        }
    }

    private func actionLinkLabel(title: String, systemImage: String, isPrimary: Bool) -> some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.title3.weight(.semibold))
            Text(title)
                .font(.system(.body, design: .rounded).weight(.semibold))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
        .foregroundStyle(isPrimary ? Color.white : DockWalkTheme.accent)
        .background(isPrimary ? DockWalkTheme.accent : DockWalkTheme.accentMuted)
        .clipShape(RoundedRectangle(cornerRadius: DockWalkTheme.cornerRadius, style: .continuous))
    }

    @ViewBuilder
    private var receivedSummarySection: some View {
        if !savedReceivedItems.isEmpty || load.status == .receiving || load.status == .complete {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Received inventory")
                            .font(DockWalkTheme.headlineFont)
                        if !savedReceivedItems.isEmpty {
                            Text("\(savedReceivedItems.count) saved")
                                .font(DockWalkTheme.captionFont)
                                .foregroundStyle(DockWalkTheme.textSecondary)
                        }
                    }
                    Spacer()
                    if load.status == .receiving {
                        NavigationLink("View all") {
                            ShipmentDetailView(
                                load: $load,
                                appointmentsViewModel: viewModel,
                                environment: environment
                            )
                        }
                        .font(DockWalkTheme.captionFont.weight(.semibold))
                    }
                }

                if savedReceivedItems.isEmpty {
                    Text("No items saved yet — start receiving to scan and capture inventory.")
                        .font(DockWalkTheme.captionFont)
                        .foregroundStyle(DockWalkTheme.textSecondary)
                } else {
                    ForEach(savedReceivedItems) { item in
                        SectionCard {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.sku.isEmpty ? item.upc : item.sku)
                                        .font(DockWalkTheme.bodyFont.weight(.semibold))
                                    if !item.sku.isEmpty, !item.upc.isEmpty, item.sku != item.upc {
                                        Text("UPC \(item.upc)")
                                            .font(DockWalkTheme.captionFont)
                                            .foregroundStyle(DockWalkTheme.textSecondary)
                                    }
                                    Text("\(item.quantityDisplay) · \(item.location)")
                                        .font(DockWalkTheme.captionFont)
                                        .foregroundStyle(DockWalkTheme.textSecondary)
                                }
                                Spacer()
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(DockWalkTheme.accent)
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        LoadDetailView(
            load: .constant(
                ReceivingAppointment(
                    id: "T-4401",
                    carrier: "Old Dominion",
                    dock: "",
                    scheduledAt: Date().addingTimeInterval(3600),
                    status: .scheduled,
                    poNumber: "T-4401",
                    palletCount: 24,
                    vendor: "Midwest Parts",
                    expectedLineCount: 0,
                    receivedLineCount: 0,
                    doorNumber: nil
                )
            ),
            viewModel: AppointmentsViewModel(),
            environment: .shared
        )
    }
    .environment(InboundSessionStore.shared)
}
