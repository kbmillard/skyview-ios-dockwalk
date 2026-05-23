import SwiftUI

struct CreateLoadView: View {
    @Environment(\.dismiss) private var dismiss
    let viewModel: AppointmentsViewModel?

    @State private var carrier = ""
    @State private var poNumber = ""
    @State private var vendor = ""
    @State private var scheduledAt = Date()
    @State private var palletCount = ""
    @State private var notes = ""
    @State private var selectedStatus: InboundLoadStatus = .scheduled
    @State private var selectedDoorNumber: String?
    @State private var showDoorPicker = false

    private var editableStatuses: [InboundLoadStatus] {
        [.scheduled, .checkedIn, .staged, .receiving, .complete, .cancelled]
    }

    private var doorDisplayLabel: String {
        selectedDoorNumber ?? "Not assigned"
    }

    var canSave: Bool {
        !carrier.trimmingCharacters(in: .whitespaces).isEmpty
            && !poNumber.trimmingCharacters(in: .whitespaces).isEmpty
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
                    .disabled(viewModel == nil)
                } footer: {
                    Text("Optional door — 30 dock doors; busy doors are unavailable. Status sets the inbound stage tab.")
                        .font(DockWalkTheme.captionFont)
                }

                Section {
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Create Load")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createLoad()
                    }
                    .disabled(!canSave)
                }
            }
            .sheet(isPresented: $showDoorPicker) {
                if let viewModel {
                    DockDoorSelectorSheet(
                        loadReference: poNumber.isEmpty ? "New load" : poNumber,
                        doorOptions: viewModel.doorPickerOptions(
                            forLoadId: nil,
                            currentSelection: selectedDoorNumber
                        ),
                        initialSelection: selectedDoorNumber,
                        allowsClear: false
                    ) { doorId in
                        selectedDoorNumber = doorId
                    }
                }
            }
        }
    }

    private func createLoad() {
        let status = resolvedStatus()
        let newLoad = ReceivingAppointment(
            id: "LOCAL-\(UUID().uuidString.prefix(8))",
            carrier: carrier.trimmingCharacters(in: .whitespaces),
            dock: selectedDoorNumber ?? "",
            scheduledAt: scheduledAt,
            status: status,
            poNumber: poNumber.trimmingCharacters(in: .whitespaces),
            palletCount: Int(palletCount) ?? 0,
            vendor: vendor.isEmpty ? nil : vendor.trimmingCharacters(in: .whitespaces),
            expectedLineCount: 0,
            receivedLineCount: 0,
            doorNumber: selectedDoorNumber
        )

        viewModel?.createLoad(newLoad)
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

#Preview {
    CreateLoadView(viewModel: AppointmentsViewModel())
}
