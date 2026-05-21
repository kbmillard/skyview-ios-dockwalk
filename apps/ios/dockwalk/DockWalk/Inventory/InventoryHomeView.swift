import SwiftUI

struct InventoryHomeView: View {
    @Environment(ScannerPreferencesStore.self) private var scannerPreferences
    @State private var viewModel = InventoryViewModel()
    @State private var showScanner = false
    @State private var selectedItem: InventoryItem?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchField
                    .padding(DockWalkTheme.screenPadding)
                
                if !viewModel.searchQuery.isEmpty {
                    itemsSection
                } else {
                    emptySearchState
                }
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
                BarcodeScannerSheet(title: "Scan inventory") { result in
                    viewModel.searchQuery = result.value
                    showScanner = false
                }
            }
            .sheet(item: $selectedItem) { item in
                InventoryItemDetailView(item: item)
            }
            .dismissScannerSheetWhenInactive(scannerPreferences, isPresented: $showScanner)
        }
    }
    
    private var emptySearchState: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(DockWalkTheme.textSecondary.opacity(0.5))
            Text("Search SKU, part, bin, or item")
                .font(DockWalkTheme.bodyFont)
                .foregroundStyle(DockWalkTheme.textSecondary)
                .multilineTextAlignment(.center)
            if scannerPreferences.isScannerActive {
                Text("Tap \(Image(systemName: "barcode.viewfinder")) to scan")
                    .font(DockWalkTheme.captionFont)
                    .foregroundStyle(DockWalkTheme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(DockWalkTheme.screenPadding)
    }

    private var searchField: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(DockWalkTheme.textSecondary)
            TextField("Search SKU, part, bin, or item", text: $viewModel.searchQuery)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            if !viewModel.searchQuery.isEmpty {
                Button {
                    viewModel.searchQuery = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(DockWalkTheme.textSecondary)
                }
            }
        }
        .padding(14)
        .background(DockWalkTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DockWalkTheme.cornerRadius))
    }

    private var itemsSection: some View {
        ScrollView {
            if viewModel.filteredItems.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundStyle(DockWalkTheme.textSecondary.opacity(0.5))
                    Text("No items match '\(viewModel.searchQuery)'")
                        .font(DockWalkTheme.bodyFont)
                        .foregroundStyle(DockWalkTheme.textSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(DockWalkTheme.screenPadding)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.filteredItems) { item in
                        itemCard(item)
                    }
                }
                .padding(DockWalkTheme.screenPadding)
            }
        }
    }
    
    private func itemCard(_ item: InventoryItem) -> some View {
        Button {
            selectedItem = item
        } label: {
            SectionCard {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(item.description)
                            .font(DockWalkTheme.headlineFont)
                            .foregroundStyle(DockWalkTheme.textPrimary)
                        
                        Text("SKU \(item.sku)")
                            .font(DockWalkTheme.captionFont)
                            .foregroundStyle(DockWalkTheme.textSecondary)
                        
                        HStack(spacing: 12) {
                            Text("Qty \(item.onHand)")
                                .font(DockWalkTheme.bodyFont)
                            Text("·")
                                .foregroundStyle(DockWalkTheme.textSecondary)
                            Text("Bin \(item.location)")
                                .font(DockWalkTheme.bodyFont)
                            Text("·")
                                .foregroundStyle(DockWalkTheme.textSecondary)
                            if item.reserved > 0 {
                                StatusChip(label: "Reserved", tone: .warning)
                            } else {
                                StatusChip(label: "Available", tone: .success)
                            }
                        }
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

#Preview {
    InventoryHomeView()
        .environment(ScannerPreferencesStore.shared)
}
