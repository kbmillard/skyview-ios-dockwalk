import SwiftUI

struct InventoryItemDetailView: View {
    let item: InventoryItem
    @Environment(\.dismiss) private var dismiss
    @State private var showMoveSheet = false
    @State private var showAdjustQuantitySheet = false
    @State private var showStatusPicker = false
    @State private var showDeleteConfirm = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DockWalkTheme.sectionSpacing) {
                    itemHeader
                    
                    metadataSection
                    
                    quantitySection
                    
                    actionsSection
                    
                    pendingNotice
                }
                .padding(DockWalkTheme.screenPadding)
            }
            .background(DockWalkTheme.background)
            .navigationTitle("Item Detail")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showMoveSheet) {
                moveLocationSheet
            }
            .sheet(isPresented: $showAdjustQuantitySheet) {
                adjustQuantitySheet
            }
            .sheet(isPresented: $showStatusPicker) {
                statusPickerSheet
            }
            .alert("Delete Item", isPresented: $showDeleteConfirm) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    // Will implement when backend ready
                }
            } message: {
                Text("Are you sure you want to delete this inventory item? This action cannot be undone.")
            }
        }
    }
    
    private var itemHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(item.itemName)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(DockWalkTheme.textPrimary)
            
            if item.status == .reserved {
                StatusChip(label: "Reserved", tone: .warning)
            } else if item.status == .onHold {
                StatusChip(label: "On Hold", tone: .warning)
            } else if item.status == .damaged {
                StatusChip(label: "Damaged", tone: .warning)
            } else {
                StatusChip(label: "Available", tone: .success)
            }
        }
    }
    
    private var metadataSection: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 12) {
                metadataRow(label: "SKU", value: item.sku)
                if let partNumber = item.partNumber {
                    Divider()
                    metadataRow(label: "Part Number", value: partNumber)
                }
                if let upc = item.upc {
                    Divider()
                    metadataRow(label: "UPC", value: upc)
                }
                Divider()
                metadataRow(label: "Location", value: item.location, icon: "mappin.and.ellipse")
            }
        }
    }
    
    private func metadataRow(label: String, value: String, icon: String? = nil) -> some View {
        HStack {
            if let icon {
                Label(label, systemImage: icon)
                    .font(DockWalkTheme.captionFont)
                    .foregroundStyle(DockWalkTheme.textSecondary)
            } else {
                Text(label)
                    .font(DockWalkTheme.captionFont)
                    .foregroundStyle(DockWalkTheme.textSecondary)
            }
            Spacer()
            Text(value)
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(DockWalkTheme.textPrimary)
        }
    }
    
    private var quantitySection: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Quantity")
                    .font(DockWalkTheme.headlineFont)
                
                HStack(spacing: 32) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("On hand")
                            .font(DockWalkTheme.captionFont)
                            .foregroundStyle(DockWalkTheme.textSecondary)
                        Text("\(item.onHand)")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(DockWalkTheme.textPrimary)
                    }
                    
                    if item.reserved > 0 {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Reserved")
                                .font(DockWalkTheme.captionFont)
                                .foregroundStyle(DockWalkTheme.textSecondary)
                            Text("\(item.reserved)")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundStyle(DockWalkTheme.warning)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Available")
                                .font(DockWalkTheme.captionFont)
                                .foregroundStyle(DockWalkTheme.textSecondary)
                            Text("\(item.onHand - item.reserved)")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundStyle(DockWalkTheme.success)
                        }
                    }
                }
            }
        }
    }
    
    private var actionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Actions")
                .font(DockWalkTheme.headlineFont)
            
            actionButton(title: "Move Material", icon: "arrow.right.circle", color: DockWalkTheme.accent) {
                showMoveSheet = true
            }
            
            actionButton(title: "Adjust Quantity", icon: "plus.forwardslash.minus", color: DockWalkTheme.accent) {
                showAdjustQuantitySheet = true
            }
            
            actionButton(title: "Change Status", icon: "circle.hexagongrid", color: DockWalkTheme.accent) {
                showStatusPicker = true
            }
            
            if item.status != .onHold {
                actionButton(title: "Place On Hold", icon: "hand.raised", color: DockWalkTheme.warning) {
                    // Will implement when backend ready
                }
            } else {
                actionButton(title: "Release Hold", icon: "checkmark.circle", color: DockWalkTheme.success) {
                    // Will implement when backend ready
                }
            }
            
            if item.status != .damaged {
                actionButton(title: "Mark Damaged", icon: "exclamationmark.triangle", color: DockWalkTheme.warning) {
                    // Will implement when backend ready
                }
            }
            
            actionButton(title: "Delete Item", icon: "trash", color: .red) {
                showDeleteConfirm = true
            }
        }
    }
    
    private func actionButton(title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            SectionCard {
                HStack {
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundStyle(color)
                        .frame(width: 28)
                    Text(title)
                        .font(DockWalkTheme.bodyFont)
                        .foregroundStyle(DockWalkTheme.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(DockWalkTheme.textSecondary)
                }
            }
        }
        .buttonStyle(.plain)
    }
    
    private var pendingNotice: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(DockWalkTheme.accent)
                    Text("Changes pending sync")
                        .font(DockWalkTheme.bodyFont.weight(.semibold))
                }
                Text("Inventory actions are recorded locally and will sync when backend integration is complete.")
                    .font(DockWalkTheme.captionFont)
                    .foregroundStyle(DockWalkTheme.textSecondary)
            }
        }
    }
    
    private var moveLocationSheet: some View {
        NavigationStack {
            VStack(spacing: DockWalkTheme.sectionSpacing) {
                Text("Move material from \(item.location) to new location")
                    .font(DockWalkTheme.bodyFont)
                    .foregroundStyle(DockWalkTheme.textSecondary)
                    .padding(DockWalkTheme.screenPadding)
                
                // Placeholder for location picker
                Text("Location picker coming soon")
                    .font(DockWalkTheme.captionFont)
                    .foregroundStyle(DockWalkTheme.textSecondary)
                
                Spacer()
            }
            .navigationTitle("Move Material")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showMoveSheet = false
                    }
                }
            }
        }
    }
    
    private var adjustQuantitySheet: some View {
        NavigationStack {
            VStack(spacing: DockWalkTheme.sectionSpacing) {
                Text("Adjust quantity for \(item.itemName)")
                    .font(DockWalkTheme.bodyFont)
                    .foregroundStyle(DockWalkTheme.textSecondary)
                    .padding(DockWalkTheme.screenPadding)
                
                // Placeholder for quantity adjuster
                Text("Quantity adjuster coming soon")
                    .font(DockWalkTheme.captionFont)
                    .foregroundStyle(DockWalkTheme.textSecondary)
                
                Spacer()
            }
            .navigationTitle("Adjust Quantity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showAdjustQuantitySheet = false
                    }
                }
            }
        }
    }
    
    private var statusPickerSheet: some View {
        NavigationStack {
            List {
                ForEach(InventoryStatus.allCases, id: \.self) { status in
                    Button {
                        // Will implement when backend ready
                        showStatusPicker = false
                    } label: {
                        HStack {
                            Text(status.displayName)
                                .foregroundStyle(DockWalkTheme.textPrimary)
                            Spacer()
                            if item.status == status {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(DockWalkTheme.accent)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Change Status")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showStatusPicker = false
                    }
                }
            }
        }
    }
}

#Preview {
    InventoryItemDetailView(item: InventoryItem(
        id: "1",
        sku: "BR-8821",
        upc: "00938122",
        partNumber: "ABC-123",
        itemName: "Brake Rotor Assembly",
        description: "Brake Rotor Assembly",
        quantity: 36,
        location: "A-14",
        status: .available,
        onHand: 36,
        reserved: 0
    ))
}
