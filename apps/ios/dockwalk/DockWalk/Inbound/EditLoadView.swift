import SwiftUI

struct EditLoadView: View {
    @Environment(\.dismiss) private var dismiss
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
                    FormValueRow(label: "Carrier", text: $carrier, placeholder: "Required", autocapitalization: .words)
                    FormValueRow(label: "PO Number", text: $poNumber, placeholder: "Required", autocapitalization: .characters)
                }

                Section {
                    FormValueRow(label: "Vendor", text: $vendor, placeholder: "Optional", autocapitalization: .words)

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
            }
            .navigationTitle("Edit Load")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveChanges() }
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

    private func saveChanges() {
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
}
