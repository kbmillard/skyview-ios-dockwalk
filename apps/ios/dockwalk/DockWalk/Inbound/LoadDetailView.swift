import SwiftUI

struct LoadDetailView: View {
    @Binding var load: ReceivingAppointment
    let viewModel: AppointmentsViewModel
    let environment: AppEnvironment

    @State private var showEditSheet = false
    @State private var showDoorSelector = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DockWalkTheme.sectionSpacing) {
                loadSummaryCard
                actionButtons
                lineItemsSection
            }
            .padding(DockWalkTheme.screenPadding)
        }
        .background(DockWalkTheme.background)
        .navigationTitle(load.poNumber)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if load.status == .scheduled || load.status == .checkedIn {
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
        applyDoor(doorId, status: .staged)
    }

    private func applyDoor(_ doorId: String?, status: InboundLoadStatus) {
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
    }

    private func checkIn() {
        applyDoor(load.assignedDoorNumber, status: .checkedIn)
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
                NavigationLink {
                    ShipmentDetailView(load: $load, appointmentsViewModel: viewModel)
                } label: {
                    actionLinkLabel(title: "Start Receiving", systemImage: "arrow.down.doc", isPrimary: false)
                }
                .buttonStyle(.plain)

            case .staged, .receiving:
                NavigationLink {
                    ShipmentDetailView(load: $load, appointmentsViewModel: viewModel)
                } label: {
                    actionLinkLabel(
                        title: load.status == .receiving ? "Resume Receiving" : "Start Receiving",
                        systemImage: "arrow.down.doc",
                        isPrimary: true
                    )
                }
                .buttonStyle(.plain)

                PrimaryActionButton(title: "Add Exception", systemImage: "exclamationmark.triangle", style: .secondary) {
                    // Add exception action
                }

            case .complete:
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

    private var lineItemsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if load.status == .receiving || load.status == .complete {
                Text("Line Items")
                    .font(DockWalkTheme.headlineFont)

                Text("Line items will appear here during receiving")
                    .font(DockWalkTheme.captionFont)
                    .foregroundStyle(DockWalkTheme.textSecondary)
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
}
