import SwiftUI

struct EditLoadView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppEnvironment.self) private var environment
    @Environment(InboundSessionStore.self) private var inboundSession
    @Environment(InventoryCatalogStore.self) private var inventoryCatalog
    @Environment(OfflineSyncStore.self) private var syncStore
    @Environment(PutawayFinalizedLoadsStore.self) private var finalizedLoads
    @Environment(FacilityConfigStore.self) private var facilityConfig
    @Binding var load: ReceivingAppointment
    let viewModel: AppointmentsViewModel

    @State private var carrier = ""
    @State private var poNumber = ""
    @State private var vendor = ""
    @State private var scheduledAt = Date()
    @State private var palletCount = ""
    @State private var selectedStatus: InboundLoadStatus = .scheduled
    @State private var selectedDoorNumber: String?
    @State private var showDoorPicker = false
    @State private var saveErrorMessage: String?
    @State private var isFinalizing = false

    private var editableStatuses: [InboundLoadStatus] {
        [.scheduled, .checkedIn, .staged, .receiving, .complete, .cancelled]
    }

    private var canSave: Bool {
        !carrier.trimmingCharacters(in: .whitespaces).isEmpty
            && !poNumber.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private var doorDisplayLabel: String {
        selectedDoorNumber ?? "Not assigned"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    FormValueRow(label: "Carrier", text: $carrier, placeholder: "Required", autocapitalizationType: .words)
                    FormValueRow(label: "PO Number", text: $poNumber, placeholder: "Required", autocapitalizationType: .allCharacters)
                }

                Section {
                    FormValueRow(label: "Vendor", text: $vendor, placeholder: "Optional", autocapitalizationType: .words)

                    DatePicker(
                        "Scheduled Arrival",
                        selection: $scheduledAt,
                        displayedComponents: [.date, .hourAndMinute]
                    )

                    FormValueRow(label: "Expected pallets", text: $palletCount, placeholder: "Optional", keyboardType: .numberPad)
                }

                Section {
                    Picker("Status", selection: $selectedStatus) {
                        ForEach(editableStatuses, id: \.self) { status in
                            Text(status.displayName).tag(status)
                        }
                    }

                    Button {
                        showDoorPicker = true
                    } label: {
                        HStack {
                            Text("Door")
                                .foregroundStyle(DockWalkTheme.textPrimary)
                            Spacer()
                            Text(doorDisplayLabel)
                                .foregroundStyle(DockWalkTheme.textSecondary)
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(DockWalkTheme.textSecondary)
                        }
                    }
                } footer: {
                    Text("Status drives which stage tab lists this load. Assigning a door moves Scheduled → Staged; clearing door moves Staged → Scheduled.")
                        .font(DockWalkTheme.captionFont)
                }
                
                if load.status == .receiving {
                    Section {
                        VStack(spacing: 16) {
                            Text("Complete this load and move it to the Complete stage.")
                                .font(DockWalkTheme.captionFont)
                                .foregroundStyle(DockWalkTheme.textSecondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            FinalizeLoadButton {
                                finalizeLoad()
                            }
                            .disabled(isFinalizing)
                        }
                        .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                    } header: {
                        Text("Finalize Load")
                    }
                } else if load.status == .complete {
                    Section {
                        Button {
                            reopenLoad()
                        } label: {
                            HStack {
                                Image(systemName: "arrow.counterclockwise")
                                Text("Re-open Load")
                            }
                            .frame(maxWidth: .infinity)
                            .foregroundStyle(DockWalkTheme.accent)
                        }
                    } header: {
                        Text("Load Actions")
                    }
                }

                if let saveErrorMessage, !saveErrorMessage.isEmpty {
                    Section {
                        Text(saveErrorMessage)
                            .font(DockWalkTheme.captionFont)
                            .foregroundStyle(DockWalkTheme.danger)
                    }
                }
            }
            .navigationTitle("Edit Load")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task { await saveChanges() }
                    }
                        .disabled(!canSave)
                }
            }
            .sheet(isPresented: $showDoorPicker) {
                DockDoorSelectorSheet(
                    loadReference: poNumber.isEmpty ? load.poNumber : poNumber,
                    doorOptions: viewModel.doorPickerOptions(
                        forLoadId: load.id,
                        currentSelection: selectedDoorNumber
                    ),
                    initialSelection: selectedDoorNumber,
                    allowsClear: false
                ) { doorId in
                    selectedDoorNumber = doorId
                }
            }
            .onAppear {
                carrier = load.carrier
                poNumber = load.poNumber
                vendor = load.vendor ?? ""
                scheduledAt = load.scheduledAt
                palletCount = load.palletCount > 0 ? String(load.palletCount) : ""
                selectedDoorNumber = load.assignedDoorNumber
                selectedStatus = load.status
            }
        }
    }

    private func saveChanges() async {
        let updated = ReceivingAppointment(
            id: load.id,
            carrier: carrier.trimmingCharacters(in: .whitespaces),
            dock: selectedDoorNumber ?? "",
            scheduledAt: scheduledAt,
            status: resolvedStatus(),
            poNumber: poNumber.trimmingCharacters(in: .whitespaces),
            palletCount: Int(palletCount) ?? 0,
            vendor: vendor.trimmingCharacters(in: .whitespaces).isEmpty
                ? nil
                : vendor.trimmingCharacters(in: .whitespaces),
            expectedLineCount: load.expectedLineCount,
            receivedLineCount: load.receivedLineCount,
            doorNumber: selectedDoorNumber
        )
        load = updated
        viewModel.updateLoad(updated)
        _ = await viewModel.syncLoadToAPI(updated)
        dismiss()
    }

    private func resolvedStatus() -> InboundLoadStatus {
        if selectedDoorNumber != nil, selectedStatus == .scheduled {
            return .staged
        }
        if selectedDoorNumber == nil, selectedStatus == .staged {
            return .scheduled
        }
        return selectedStatus
    }
    
    private func finalizeLoad() {
        let saved = inboundSession.receivedItems(for: load.id).filter(\.isSaved)
        let staging = facilityConfig.defaultReceiveLocation()
        let lines: [InboundFinalizeLine] = saved.compactMap { draft in
            let upc = draft.upc.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !upc.isEmpty else { return nil }
            let sku = draft.sku.trimmingCharacters(in: .whitespacesAndNewlines)
            let loc = draft.location.trimmingCharacters(in: .whitespacesAndNewlines)
            let locationCode = loc.isEmpty ? staging : loc
            return InboundFinalizeLine(
                clientLineId: draft.id,
                upc: upc,
                sku: sku.isEmpty ? nil : sku,
                isUnregisteredUPC: sku.isEmpty,
                cases: draft.parsedCases,
                eachesPerCase: draft.parsedEaches,
                locationCode: locationCode,
                status: draft.status.rawValue
            )
        }
        let payload = InboundFinalizeRequest(
            idempotencyKey: UUID().uuidString,
            facilityId: environment.facilityId,
            lines: lines
        )
        isFinalizing = true
        saveErrorMessage = nil
        Task {
            var canComplete = false
            let client = environment.makeAPIClient()
            do {
                try await client.finalizeInboundLoad(loadId: load.id, body: payload)
                canComplete = true
            } catch {
                if APIClientErrorClassifier.shouldQueueOffline(for: error) {
                    syncStore.enqueueFinalizeLoad(
                        loadId: load.id,
                        payload: payload,
                        summary: "Finalize load \(load.poNumber)"
                    )
                    canComplete = true
                } else {
                    saveErrorMessage = "Finalize failed. Resolve and retry."
                }
            }
            if canComplete {
                inboundSession.commitReceivedInventoryToCatalog(loadId: load.id, catalog: inventoryCatalog)
                finalizedLoads.markFinalized(loadId: load.id)
                selectedStatus = .complete
                await saveChanges()
            }
            isFinalizing = false
        }
    }
    
    private func reopenLoad() {
        selectedStatus = .receiving
        Task { await saveChanges() }
    }
}
