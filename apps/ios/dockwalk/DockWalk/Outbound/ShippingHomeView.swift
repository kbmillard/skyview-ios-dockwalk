import SwiftUI

struct ShippingHomeView: View {
    @Environment(ScannerPreferencesStore.self) private var scannerPreferences
    @State private var viewModel = OutboundViewModel()
    @State private var showScanner = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DockWalkTheme.sectionSpacing) {
                    FoundationAreaBanner(
                        title: "Outbound foundation",
                        detail: "Pick, stage, load, and closeout structure ready. Full outbound workflows and inventory decrement will expand in a later release."
                    )
                    
                    outboundSummary
                    
                    if scannerPreferences.isScannerActive {
                        PrimaryActionButton(title: "Scan Load", systemImage: "barcode.viewfinder") {
                            showScanner = true
                        }
                    }
                    
                    outboundCommandSection
                    
                    activeLoadsSection
                    
                    pickingSection
                    
                    closeoutSection
                }
                .padding(DockWalkTheme.screenPadding)
            }
            .background(DockWalkTheme.background)
            .navigationTitle("Ship")
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
            .dismissScannerSheetWhenInactive(scannerPreferences, isPresented: $showScanner)
        }
    }

    private var outboundSummary: some View {
        HStack(spacing: 12) {
            SectionCard {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Active loads")
                        .font(DockWalkTheme.captionFont)
                        .foregroundStyle(DockWalkTheme.textSecondary)
                    Text("\(viewModel.activeLoadsCount)")
                        .font(.system(size: 32, weight: .semibold, design: .rounded))
                }
            }
            SectionCard {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Staged")
                        .font(DockWalkTheme.captionFont)
                        .foregroundStyle(DockWalkTheme.textSecondary)
                    Text("\(viewModel.stagedCount)")
                        .font(.system(size: 32, weight: .semibold, design: .rounded))
                }
            }
            SectionCard {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Picking")
                        .font(DockWalkTheme.captionFont)
                        .foregroundStyle(DockWalkTheme.textSecondary)
                    Text("\(viewModel.pickingCount)")
                        .font(.system(size: 32, weight: .semibold, design: .rounded))
                }
            }
        }
    }
    
    private var outboundCommandSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Operations")
                .font(DockWalkTheme.headlineFont)
            
            HStack(spacing: 12) {
                Button {
                } label: {
                    SectionCard {
                        HStack {
                            Image(systemName: "cart")
                                .font(.title2)
                                .foregroundStyle(DockWalkTheme.accent)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Pick")
                                    .font(DockWalkTheme.headlineFont)
                                Text("Start wave")
                                    .font(DockWalkTheme.captionFont)
                                    .foregroundStyle(DockWalkTheme.textSecondary)
                            }
                            Spacer()
                        }
                    }
                }
                .buttonStyle(.plain)
                
                Button {
                } label: {
                    SectionCard {
                        HStack {
                            Image(systemName: "square.stack.3d.up")
                                .font(.title2)
                                .foregroundStyle(DockWalkTheme.accent)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Stage")
                                    .font(DockWalkTheme.headlineFont)
                                Text("Assign door")
                                    .font(DockWalkTheme.captionFont)
                                    .foregroundStyle(DockWalkTheme.textSecondary)
                            }
                            Spacer()
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var activeLoadsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Loading")
                .font(DockWalkTheme.headlineFont)
            
            if viewModel.loadingOrders.isEmpty {
                SectionCard {
                    VStack(spacing: 8) {
                        Image(systemName: "truck.box")
                            .font(.largeTitle)
                            .foregroundStyle(DockWalkTheme.textSecondary)
                        Text("No active loads")
                            .font(DockWalkTheme.bodyFont)
                            .foregroundStyle(DockWalkTheme.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                }
            } else {
                ForEach(viewModel.loadingOrders) { order in
                    SectionCard {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(order.customer)
                                    .font(DockWalkTheme.headlineFont)
                                Spacer()
                                StatusChip(label: order.status.displayName, tone: order.status.chipTone)
                            }
                            HStack(spacing: 16) {
                                Label(order.door, systemImage: "door.right.hand.open")
                                Label("\(order.cartonCount) cartons", systemImage: "shippingbox")
                            }
                            .font(DockWalkTheme.captionFont)
                            .foregroundStyle(DockWalkTheme.textSecondary)
                        }
                    }
                }
            }
        }
    }
    
    private var pickingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Picking & staged")
                .font(DockWalkTheme.headlineFont)
            
            if viewModel.pickingAndStagedOrders.isEmpty {
                SectionCard {
                    Text("No orders in picking or staged status.")
                        .font(DockWalkTheme.bodyFont)
                        .foregroundStyle(DockWalkTheme.textSecondary)
                }
            } else {
                ForEach(viewModel.pickingAndStagedOrders) { order in
                    SectionCard {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(order.customer)
                                    .font(DockWalkTheme.headlineFont)
                                if !order.door.isEmpty {
                                    Label(order.door, systemImage: "door.right.hand.open")
                                }
                                Label("\(order.cartonCount) cartons", systemImage: "shippingbox")
                            }
                            .font(DockWalkTheme.captionFont)
                            .foregroundStyle(DockWalkTheme.textSecondary)
                            Spacer()
                            StatusChip(label: order.status.displayName, tone: order.status.chipTone)
                        }
                    }
                }
            }
        }
    }

    private var closeoutSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Closeout")
                .font(DockWalkTheme.headlineFont)
            
            if viewModel.readyToCloseOrders.isEmpty {
                SectionCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("No loads ready for closeout")
                            .font(DockWalkTheme.bodyFont)
                        Text("Loads ready for trailer verification and BOL sign-off will appear here.")
                            .font(DockWalkTheme.captionFont)
                            .foregroundStyle(DockWalkTheme.textSecondary)
                    }
                }
            } else {
                ForEach(viewModel.readyToCloseOrders) { order in
                    SectionCard {
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(order.customer)
                                    .font(DockWalkTheme.headlineFont)
                                HStack(spacing: 16) {
                                    Label(order.door, systemImage: "door.right.hand.open")
                                    Label("\(order.cartonCount) cartons", systemImage: "shippingbox")
                                }
                                .font(DockWalkTheme.captionFont)
                                .foregroundStyle(DockWalkTheme.textSecondary)
                            }
                            Spacer()
                            StatusChip(label: order.status.displayName, tone: order.status.chipTone)
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    ShippingHomeView()
}
