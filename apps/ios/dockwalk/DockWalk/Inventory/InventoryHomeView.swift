import SwiftUI

struct InventoryHomeView: View {
    @Environment(ScannerPreferencesStore.self) private var scannerPreferences
    @Environment(InventoryScannerCoordinator.self) private var inventoryScannerCoordinator
    @Environment(InventoryCatalogStore.self) private var inventoryCatalog
    @State private var viewModel = InventoryViewModel()
    @State private var showScanner = false
    @State private var showAddInventory = false
    @State private var selectedItem: InventoryItem?
    @State private var lastHandledScanToken = 0

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
            .sheet(isPresented: $showScanner) {
                BarcodeScannerSheet(title: "Scan inventory", applyStyle: .direct) { result in
                    applyScannedCode(result.value)
                }
            }
            .sheet(isPresented: $showAddInventory) {
                InventoryAddSheet(initialCode: viewModel.searchQuery) { _ in
                    viewModel.refreshFromCatalog()
                }
            }
            .sheet(item: $selectedItem) { item in
                InventoryItemDetailView(item: item)
            }
            .dismissScannerSheetWhenInactive(scannerPreferences, isPresented: $showScanner)
            .onAppear {
                viewModel.refreshFromCatalog()
                handleFloatingScanRequestIfNeeded()
            }
            .onChange(of: inventoryScannerCoordinator.openScannerToken) { _, _ in
                handleFloatingScanRequestIfNeeded()
            }
            .onChange(of: inventoryCatalog.revision) { _, _ in
                viewModel.refreshFromCatalog()
            }
        }
    }

    private func applyScannedCode(_ value: String) {
        viewModel.searchQuery = value
        showScanner = false
        viewModel.refreshFromCatalog()
    }

    private func handleFloatingScanRequestIfNeeded() {
        let token = inventoryScannerCoordinator.openScannerToken
        guard token != lastHandledScanToken else { return }
        lastHandledScanToken = token
        guard scannerPreferences.isScannerActive else { return }
        showScanner = true
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
                Text("Use the scan button below to scan a barcode")
                    .font(DockWalkTheme.captionFont)
                    .foregroundStyle(DockWalkTheme.textSecondary)
                    .multilineTextAlignment(.center)
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
            if viewModel.isScannedCodeNotFound {
                upcNotFoundState
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

    private var upcNotFoundState: some View {
        VStack(spacing: 16) {
            Image(systemName: "barcode.viewfinder")
                .font(.system(size: 48))
                .foregroundStyle(DockWalkTheme.textSecondary.opacity(0.5))
            Text("UPC not found")
                .font(DockWalkTheme.headlineFont)
            Text(viewModel.searchQuery)
                .font(.system(.body, design: .monospaced).weight(.semibold))
            Text("No inventory matches this code.")
                .font(DockWalkTheme.captionFont)
                .foregroundStyle(DockWalkTheme.textSecondary)
                .multilineTextAlignment(.center)
            PrimaryActionButton(title: "Add inventory?", systemImage: "plus.rectangle.on.rectangle") {
                showAddInventory = true
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(DockWalkTheme.screenPadding)
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
        .environment(InventoryScannerCoordinator.shared)
        .environment(InventoryCatalogStore.shared)
}
