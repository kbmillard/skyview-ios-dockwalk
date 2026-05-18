import SwiftUI

struct InventoryHomeView: View {
    @Environment(ScannerPreferencesStore.self) private var scannerPreferences
    @State private var viewModel = InventoryViewModel()
    @State private var showScanner = false
    @State private var showLocationLookup = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DockWalkTheme.sectionSpacing) {
                    inventorySummary
                    
                    quickActions
                    
                    searchField
                    
                    itemsSection
                    
                    recentMovementSection
                    
                    cycleCountSection
                    
                    foundationNotice
                }
                .padding(DockWalkTheme.screenPadding)
            }
            .background(DockWalkTheme.background)
            .navigationTitle("Inventory")
            .toolbar {
                if scannerPreferences.isScannerActive {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showScanner = true
                        } label: {
                            Image(systemName: "barcode.viewfinder")
                                .font(.body.weight(.semibold))
                        }
                    }
                }
            }
            .sheet(isPresented: $showScanner) {
                NavigationStack {
                    ScannerLabView()
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Done") { showScanner = false }
                            }
                        }
                }
            }
            .sheet(isPresented: $showLocationLookup) {
                NavigationStack {
                    LocationLookupView()
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Done") { showLocationLookup = false }
                            }
                        }
                }
            }
            .dismissScannerSheetWhenInactive(scannerPreferences, isPresented: $showScanner)
        }
    }
    
    private var inventorySummary: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Inventory summary")
                .font(DockWalkTheme.headlineFont)
            
            HStack(spacing: 12) {
                SectionCard {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("SKUs on hand")
                            .font(DockWalkTheme.captionFont)
                            .foregroundStyle(DockWalkTheme.textSecondary)
                        Text("\(viewModel.items.count)")
                            .font(.system(size: 28, weight: .semibold, design: .rounded))
                    }
                }
                SectionCard {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Total units")
                            .font(DockWalkTheme.captionFont)
                            .foregroundStyle(DockWalkTheme.textSecondary)
                        Text("\(viewModel.totalOnHandUnits)")
                            .font(.system(size: 28, weight: .semibold, design: .rounded))
                    }
                }
                SectionCard {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Reserved")
                            .font(DockWalkTheme.captionFont)
                            .foregroundStyle(DockWalkTheme.textSecondary)
                        Text("\(viewModel.totalReservedUnits)")
                            .font(.system(size: 28, weight: .semibold, design: .rounded))
                            .foregroundStyle(DockWalkTheme.warning)
                    }
                }
            }
        }
    }
    
    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick actions")
                .font(DockWalkTheme.headlineFont)
            
            HStack(spacing: 12) {
                Button {
                    showLocationLookup = true
                } label: {
                    SectionCard {
                        HStack {
                            Image(systemName: "mappin.and.ellipse")
                                .font(.title3)
                                .foregroundStyle(DockWalkTheme.accent)
                                .frame(width: 28)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Location lookup")
                                    .font(DockWalkTheme.bodyFont)
                                Text("Find by bin")
                                    .font(DockWalkTheme.captionFont)
                                    .foregroundStyle(DockWalkTheme.textSecondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(DockWalkTheme.textSecondary)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var searchField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Search inventory")
                .font(DockWalkTheme.headlineFont)
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(DockWalkTheme.textSecondary)
                TextField("Search SKU, description, location", text: $viewModel.searchQuery)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
            .padding(14)
            .background(DockWalkTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: DockWalkTheme.cornerRadius))
        }
    }

    private var itemsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("On-hand items")
                    .font(DockWalkTheme.headlineFont)
                Spacer()
                if !viewModel.searchQuery.isEmpty, !viewModel.filteredItems.isEmpty {
                    StatusChip(label: "\(viewModel.filteredItems.count) found", tone: .info)
                }
            }
            
            if viewModel.filteredItems.isEmpty && !viewModel.searchQuery.isEmpty {
                SectionCard {
                    VStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .font(.largeTitle)
                            .foregroundStyle(DockWalkTheme.textSecondary)
                        Text("No items match '\(viewModel.searchQuery)'")
                            .font(DockWalkTheme.bodyFont)
                            .foregroundStyle(DockWalkTheme.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                }
            } else {
                ForEach(viewModel.filteredItems) { item in
                    itemCard(item)
                }
            }
        }
    }
    
    private func itemCard(_ item: InventoryItem) -> some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(item.sku)
                        .font(.system(.body, design: .monospaced).weight(.semibold))
                    Spacer()
                    if item.reserved > 0 {
                        StatusChip(label: "Reserved", tone: .warning)
                    }
                }
                Text(item.description)
                    .font(DockWalkTheme.bodyFont)
                    .foregroundStyle(DockWalkTheme.textPrimary)
                Label(item.location, systemImage: "mappin.and.ellipse")
                    .font(DockWalkTheme.captionFont)
                    .foregroundStyle(DockWalkTheme.textSecondary)
                Divider()
                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("On hand")
                            .font(DockWalkTheme.captionFont)
                            .foregroundStyle(DockWalkTheme.textSecondary)
                        Text("\(item.onHand)")
                            .font(.system(.body, design: .rounded).weight(.semibold))
                    }
                    if item.reserved > 0 {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Reserved")
                                .font(DockWalkTheme.captionFont)
                                .foregroundStyle(DockWalkTheme.textSecondary)
                            Text("\(item.reserved)")
                                .font(.system(.body, design: .rounded).weight(.semibold))
                                .foregroundStyle(DockWalkTheme.warning)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Available")
                                .font(DockWalkTheme.captionFont)
                                .foregroundStyle(DockWalkTheme.textSecondary)
                            Text("\(item.onHand - item.reserved)")
                                .font(.system(.body, design: .rounded).weight(.semibold))
                                .foregroundStyle(DockWalkTheme.success)
                        }
                    }
                }
            }
        }
    }
    
    private var recentMovementSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent movement")
                .font(DockWalkTheme.headlineFont)
            
            if viewModel.recentMovements.isEmpty {
                SectionCard {
                    Text("No recent movement.")
                        .font(DockWalkTheme.bodyFont)
                        .foregroundStyle(DockWalkTheme.textSecondary)
                }
            } else {
                ForEach(viewModel.recentMovements) { movement in
                    NavigationLink {
                        ActivityView()
                    } label: {
                        SectionCard {
                            HStack {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(movement.sku)
                                        .font(.system(.body, design: .monospaced).weight(.semibold))
                                    HStack(spacing: 8) {
                                        Label(movement.fromLocation, systemImage: "arrow.right")
                                        Text(movement.toLocation)
                                    }
                                    .font(DockWalkTheme.captionFont)
                                    .foregroundStyle(DockWalkTheme.textSecondary)
                                    Text(movement.timestamp.formatted(date: .abbreviated, time: .shortened))
                                        .font(DockWalkTheme.captionFont)
                                        .foregroundStyle(DockWalkTheme.textSecondary)
                                }
                                Spacer()
                                Text("\(movement.quantity)")
                                    .font(.system(.title3, design: .rounded).weight(.semibold))
                                    .foregroundStyle(DockWalkTheme.textSecondary)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
                Text("Full movement history available in Activity audit trail.")
                    .font(DockWalkTheme.captionFont)
                    .foregroundStyle(DockWalkTheme.textSecondary)
            }
        }
    }

    private var cycleCountSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Cycle count")
                .font(DockWalkTheme.headlineFont)
            
            if viewModel.cycleCounts.isEmpty {
                SectionCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("No active cycle count")
                            .font(DockWalkTheme.bodyFont)
                        Text("Scheduled cycle counts will appear here when assigned to this facility.")
                            .font(DockWalkTheme.captionFont)
                            .foregroundStyle(DockWalkTheme.textSecondary)
                    }
                }
            } else {
                ForEach(viewModel.cycleCounts) { task in
                    SectionCard {
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(task.zone)
                                    .font(DockWalkTheme.headlineFont)
                                Text("\(task.locationsRemaining) locations remaining")
                                    .font(DockWalkTheme.captionFont)
                                    .foregroundStyle(DockWalkTheme.textSecondary)
                            }
                            Spacer()
                            StatusChip(label: "Open", tone: .info)
                        }
                    }
                }
            }
        }
    }
    
    private var foundationNotice: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(DockWalkTheme.accent)
                    Text("Inventory foundation — stable local data")
                        .font(DockWalkTheme.bodyFont.weight(.semibold))
                }
                Text("Location lookup, on-hand search, and cycle count structure ready. Full inventory control, adjustments, and live API integration will expand in a later release.")
                    .font(DockWalkTheme.captionFont)
                    .foregroundStyle(DockWalkTheme.textSecondary)
            }
        }
    }
}

#Preview {
    InventoryHomeView()
        .environment(ScannerPreferencesStore.shared)
}
