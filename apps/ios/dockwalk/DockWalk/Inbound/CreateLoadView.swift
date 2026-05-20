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
    
    var canSave: Bool {
        !carrier.trimmingCharacters(in: .whitespaces).isEmpty
        && !poNumber.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Carrier (required)", text: $carrier)
                        .autocapitalization(.words)
                    TextField("PO Number (required)", text: $poNumber)
                        .textInputAutocapitalization(.characters)
                }
                
                Section {
                    TextField("Vendor (optional)", text: $vendor)
                        .autocapitalization(.words)
                    
                    DatePicker("Scheduled Arrival", selection: $scheduledAt, in: Date()...)
                    
                    TextField("Expected Pallet Count (optional)", text: $palletCount)
                        .keyboardType(.numberPad)
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
        }
    }
    
    private func createLoad() {
        let newLoad = ReceivingAppointment(
            id: "LOCAL-\(UUID().uuidString.prefix(8))",
            carrier: carrier.trimmingCharacters(in: .whitespaces),
            dock: "",
            scheduledAt: scheduledAt,
            status: .scheduled,
            poNumber: poNumber.trimmingCharacters(in: .whitespaces),
            palletCount: Int(palletCount) ?? 0,
            vendor: vendor.isEmpty ? nil : vendor.trimmingCharacters(in: .whitespaces),
            expectedLineCount: 0,
            receivedLineCount: 0,
            doorNumber: nil
        )
        
        viewModel?.createLoad(newLoad)
        dismiss()
    }
}

#Preview {
    CreateLoadView(viewModel: nil)
}
