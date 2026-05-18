import SwiftUI

struct InventoryHomeView: View {
    @Environment(ScannerPreferencesStore.self) private var scannerPreferences
    @State private var viewModel = InventoryViewModel()
    @State private var showScanner = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DockWalkTheme.sectionSpacing) {
                    FoundationAreaBanner(
                        title: "Inventory foundation",
                        detail: "On-hand lookup and cycle count will expand in a later release. Sample SKUs below are for layout preview — not live inventory control."
                    )
                    searchField
                    if scannerPreferences.isScannerActive {
                        PrimaryActionButton(title: "Scan Item", systemImage: "barcode.viewfinder") {
                            showScanner = true
                        }
                    }
                    itemsSection
                    cycleCountSection
                }
                .padding(DockWalkTheme.screenPadding)
            }
            .background(DockWalkTheme.background)
            .navigationTitle("Inventory")
            .sheet(isPresented: $showScanner) {
                ScannerLabView()
            }
            .dismissScannerSheetWhenInactive(scannerPreferences, isPresented: $showScanner)
        }
    }

    private var searchField: some View {
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

    private var itemsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Items")
                .font(DockWalkTheme.headlineFont)
            ForEach(viewModel.filteredItems) { item in
                SectionCard {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(item.sku)
                            .font(.system(.body, design: .monospaced).weight(.semibold))
                        Text(item.description)
                            .font(DockWalkTheme.bodyFont)
                        Label(item.location, systemImage: "mappin.and.ellipse")
                            .font(DockWalkTheme.captionFont)
                            .foregroundStyle(DockWalkTheme.textSecondary)
                        HStack {
                            Text("On hand: \(item.onHand)")
                            if item.reserved > 0 {
                                Text("Reserved: \(item.reserved)")
                                    .foregroundStyle(DockWalkTheme.warning)
                            }
                        }
                        .font(DockWalkTheme.captionFont)
                    }
                }
            }
        }
    }

    private var cycleCountSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Cycle count")
                .font(DockWalkTheme.headlineFont)
            ForEach(viewModel.cycleCounts) { task in
                SectionCard {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
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

#Preview {
    InventoryHomeView()
}
