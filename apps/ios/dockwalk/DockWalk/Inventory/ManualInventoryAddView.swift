import SwiftUI

/// Form for manually adding inventory items.
struct ManualInventoryAddView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppEnvironment.self) private var appEnvironment
    @Environment(InventoryCatalogStore.self) private var catalog
    
    @State private var sku = ""
    @State private var upc = ""
    @State private var partDescription = ""
    @State private var itemName = ""
    @State private var quantity = ""
    @State private var location = ""
    @State private var selectedStatus: InventoryStatus = .available
    @State private var isSaving = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Tokens.Space.lg) {
                    // Form fields
                    VStack(spacing: Tokens.Space.base) {
                        formField(
                            label: "SKU",
                            placeholder: "",
                            text: $sku,
                            isRequired: true
                        )

                        formField(
                            label: "UPC",
                            placeholder: "",
                            text: $upc,
                            isRequired: false
                        )

                        formField(
                            label: "Part name",
                            placeholder: "",
                            text: $itemName,
                            isRequired: true
                        )

                        formField(
                            label: "Part description",
                            placeholder: "Optional",
                            text: $partDescription,
                            isRequired: false
                        )

                        formField(
                            label: "Qty",
                            placeholder: "",
                            text: $quantity,
                            isRequired: true,
                            keyboardType: .numberPad
                        )

                        formField(
                            label: "Location",
                            placeholder: "",
                            text: $location,
                            isRequired: true
                        )
                        
                        // Status picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Status")
                                .font(Tokens.Font.bodySecondary)
                                .foregroundStyle(Tokens.Color.Ink.secondary)
                            
                            HStack(spacing: 8) {
                                ForEach(InventoryStatus.allCases, id: \.rawValue) { status in
                                    statusChip(status)
                                }
                            }
                        }
                    }
                    
                    // Error message
                    if let errorMessage {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                            Text(errorMessage)
                                .font(Tokens.Font.bodySecondary)
                        }
                        .foregroundStyle(Tokens.Color.Signal.critical)
                        .padding(Tokens.Space.base)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Tokens.Color.Signal.critical.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: Tokens.Radius.card, style: .continuous))
                    }
                    
                    // Save button
                    PrimaryActionButton(
                        title: "Add to Inventory",
                        systemImage: "checkmark.circle.fill"
                    ) {
                        saveInventory()
                    }
                    .disabled(!isFormValid || isSaving)
                }
                .padding(DockWalkTheme.screenPadding)
            }
            .background(DockWalkTheme.background)
            .navigationTitle("Manual Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isSaving)
                }
            }
        }
    }
    
    private func formField(
        label: String,
        placeholder: String,
        text: Binding<String>,
        isRequired: Bool,
        keyboardType: UIKeyboardType = .default
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                Text(label)
                    .font(Tokens.Font.bodySecondary)
                    .foregroundStyle(Tokens.Color.Ink.secondary)
                
                if isRequired {
                    Text("*")
                        .font(Tokens.Font.bodySecondary)
                        .foregroundStyle(Tokens.Color.Signal.critical)
                }
            }
            
            CursorAtEndTextField(
                placeholder: placeholder,
                text: text,
                keyboardType: keyboardType,
                autocapitalizationType: keyboardType == .numberPad ? .none : .words,
                textAlignment: .natural
            )
            .font(Tokens.Font.bodyDefault)
            .padding(Tokens.Space.base)
            .background(Tokens.Color.Surface.card)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Tokens.Color.Divider.hairline, lineWidth: 0.5)
            )
        }
    }
    
    private func statusChip(_ status: InventoryStatus) -> some View {
        Button {
            selectedStatus = status
            Haptics.scanSuccess()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: status.systemImage)
                    .font(.caption.weight(.semibold))
                Text(status.displayName)
                    .font(Tokens.Font.bodySecondary)
            }
            .padding(.horizontal, Tokens.Space.md)
            .padding(.vertical, 8)
            .background(
                selectedStatus == status
                    ? Tokens.Color.Accent.horizon
                    : Tokens.Color.Surface.card
            )
            .foregroundStyle(
                selectedStatus == status
                    ? Tokens.Color.Ink.inverse
                    : Tokens.Color.Ink.primary
            )
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(
                        selectedStatus == status
                            ? Color.clear
                            : Tokens.Color.Divider.hairline,
                        lineWidth: 0.5
                    )
            )
        }
        .buttonStyle(.plain)
    }
    
    private var isFormValid: Bool {
        !sku.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !itemName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !quantity.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        Int(quantity) != nil &&
        Int(quantity)! > 0
    }
    
    private func saveInventory() {
        errorMessage = nil
        isSaving = true
        
        Task {
            do {
                // Validate quantity
                guard let quantityInt = Int(quantity), quantityInt > 0 else {
                    throw InventoryError.invalidQuantity
                }
                
                // Create the inventory item
                let trimmedUPC = upc.trimmingCharacters(in: .whitespacesAndNewlines)
                let newItem = InventoryItem(
                    id: UUID().uuidString,
                    sku: sku.trimmingCharacters(in: .whitespacesAndNewlines),
                    upc: trimmedUPC.isEmpty ? nil : trimmedUPC,
                    partDescription: partDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        ? nil
                        : partDescription.trimmingCharacters(in: .whitespacesAndNewlines),
                    itemName: itemName.trimmingCharacters(in: .whitespacesAndNewlines),
                    description: itemName.trimmingCharacters(in: .whitespacesAndNewlines),
                    quantity: quantityInt,
                    location: location.trimmingCharacters(in: .whitespacesAndNewlines),
                    status: selectedStatus,
                    onHand: quantityInt,
                    reserved: 0
                )
                
                await MainActor.run {
                    catalog.add(newItem)
                    isSaving = false
                    Haptics.scanSuccess()
                    dismiss()
                }

                let client = appEnvironment.makeAPIClient()
                try? await client.addInventoryItem(newItem)
            } catch {
                await MainActor.run {
                    isSaving = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

enum InventoryError: LocalizedError {
    case invalidQuantity
    
    var errorDescription: String? {
        switch self {
        case .invalidQuantity:
            return "Quantity must be a positive number"
        }
    }
}

// Extension to add inventory item to API client
extension APIClient {
    func addInventoryItem(_ item: InventoryItem) async throws {
        // For now, this is a placeholder
        // In production, this would make a POST request to /api/inventory
        try await Task.sleep(nanoseconds: 500_000_000) // Simulate network delay
        
        // TODO: Implement actual API call
        // let request = try makeRequest(.POST, "/api/inventory", body: item)
        // _ = try await urlSession.data(for: request)
    }
}

#Preview {
    ManualInventoryAddView()
        .environment(AppEnvironment.shared)
        .environment(InventoryCatalogStore.shared)
}
