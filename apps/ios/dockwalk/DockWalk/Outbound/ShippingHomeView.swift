import SwiftUI

struct ShippingHomeView: View {
    @Environment(ScannerPreferencesStore.self) private var scannerPreferences
    @State private var viewModel = OutboundViewModel()
    @State private var showScanner = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DockWalkTheme.sectionSpacing) {
                workflowSummary
                
                stagedSection
                
                loadingSection
                
                foundationNotice
            }
            .padding(DockWalkTheme.screenPadding)
        }
        .background(DockWalkTheme.background)
        .navigationTitle("Shipping")
        .navigationBarTitleDisplayMode(.large)
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
        .dismissScannerSheetWhenInactive(scannerPreferences, isPresented: $showScanner)
    }

    private var workflowSummary: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Outbound summary")
                .font(DockWalkTheme.headlineFont)
            
            HStack(spacing: 12) {
                SectionCard {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Ready to pick")
                            .font(DockWalkTheme.captionFont)
                            .foregroundStyle(DockWalkTheme.textSecondary)
                        Text("\(viewModel.readyToPickCount)")
                            .font(.system(size: 28, weight: .semibold, design: .rounded))
                    }
                }
                SectionCard {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Picking")
                            .font(DockWalkTheme.captionFont)
                            .foregroundStyle(DockWalkTheme.textSecondary)
                        Text("\(viewModel.pickingCount)")
                            .font(.system(size: 28, weight: .semibold, design: .rounded))
                    }
                }
                SectionCard {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Loading")
                            .font(DockWalkTheme.captionFont)
                            .foregroundStyle(DockWalkTheme.textSecondary)
                        Text("\(viewModel.activeLoadsCount)")
                            .font(.system(size: 28, weight: .semibold, design: .rounded))
                    }
                }
            }
        }
    }
    
    private var readyToPickSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Ready to pick")
                    .font(DockWalkTheme.headlineFont)
                Spacer()
                if !viewModel.readyToPickOrders.isEmpty {
                    StatusChip(label: "\(viewModel.readyToPickCount)", tone: .neutral)
                }
            }
            
            NavigationLink {
                PickingTasksView()
            } label: {
                HStack {
                    Text("Open picking queue")
                        .font(DockWalkTheme.bodyFont.weight(.semibold))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                }
                .foregroundStyle(DockWalkTheme.accent)
            }
            
            if viewModel.readyToPickOrders.isEmpty {
                SectionCard {
                    VStack(spacing: 8) {
                        Image(systemName: "cart")
                            .font(.largeTitle)
                            .foregroundStyle(DockWalkTheme.textSecondary)
                        Text("No orders ready to pick")
                            .font(DockWalkTheme.bodyFont)
                            .foregroundStyle(DockWalkTheme.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                }
            } else {
                ForEach(viewModel.readyToPickOrders) { order in
                    jobCard(order)
                }
            }
        }
    }
    
    private var pickingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Picking")
                    .font(DockWalkTheme.headlineFont)
                Spacer()
                if viewModel.pickingCount > 0 {
                    StatusChip(label: "\(viewModel.pickingCount)", tone: .info)
                }
            }
            
            NavigationLink {
                PickingTasksView()
            } label: {
                HStack {
                    Text("Open picking queue")
                        .font(DockWalkTheme.bodyFont.weight(.semibold))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                }
                .foregroundStyle(DockWalkTheme.accent)
            }
            
            if viewModel.pickingOrders.isEmpty && viewModel.pickedOrders.isEmpty {
                SectionCard {
                    Text("No orders in picking status.")
                        .font(DockWalkTheme.bodyFont)
                        .foregroundStyle(DockWalkTheme.textSecondary)
                }
            } else {
                ForEach(viewModel.pickingOrders) { order in
                    jobCard(order)
                }
                ForEach(viewModel.pickedOrders) { order in
                    jobCard(order)
                }
            }
        }
    }
    
    private var stagedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Staged for loading")
                    .font(DockWalkTheme.headlineFont)
                Spacer()
                if viewModel.stagedCount > 0 {
                    StatusChip(label: "\(viewModel.stagedCount)", tone: .neutral)
                }
            }
            
            if viewModel.stagedOrders.isEmpty {
                SectionCard {
                    Text("No orders staged.")
                        .font(DockWalkTheme.bodyFont)
                        .foregroundStyle(DockWalkTheme.textSecondary)
                }
            } else {
                ForEach(viewModel.stagedOrders) { order in
                    jobCard(order)
                }
            }
        }
    }
    
    private var loadingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Loading now")
                    .font(DockWalkTheme.headlineFont)
                Spacer()
                if viewModel.activeLoadsCount > 0 {
                    StatusChip(label: "\(viewModel.activeLoadsCount)", tone: .warning)
                }
            }
            
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
                    jobCard(order)
                }
            }
        }
    }
    
    @ViewBuilder
    private func jobCard(_ order: OutboundOrder) -> some View {
        let card = SectionCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text(order.orderNumber)
                                .font(.system(.body, design: .monospaced).weight(.semibold))
                            if order.priority == .urgent {
                                StatusChip(label: "Urgent", tone: .warning)
                            }
                        }
                        Text(order.customer)
                            .font(DockWalkTheme.headlineFont)
                    }
                    Spacer()
                    StatusChip(label: order.status.displayName, tone: order.status.chipTone)
                }
                
                HStack(spacing: 16) {
                    Label("\(order.lineCount) lines", systemImage: "list.bullet")
                    Label("\(order.cartonCount) cartons", systemImage: "shippingbox")
                    if !order.door.isEmpty {
                        Label(order.door, systemImage: "door.right.hand.open")
                    }
                }
                .font(DockWalkTheme.captionFont)
                .foregroundStyle(DockWalkTheme.textSecondary)
                
                if let assignedTo = order.assignedTo {
                    HStack {
                        Image(systemName: "person.fill")
                        Text(assignedTo)
                    }
                    .font(DockWalkTheme.captionFont)
                    .foregroundStyle(DockWalkTheme.accent)
                }
                
                if let shipDate = order.shipDate {
                    HStack {
                        Image(systemName: "calendar")
                        Text("Ship: \(shipDate.formatted(date: .abbreviated, time: .omitted))")
                    }
                    .font(DockWalkTheme.captionFont)
                    .foregroundStyle(DockWalkTheme.textSecondary)
                }
            }
        }

        switch order.status {
        case .readyToPick, .picking, .picked:
            NavigationLink {
                PickingTasksView()
            } label: {
                card
            }
            .buttonStyle(.plain)
        case .staged, .loading:
            NavigationLink {
                ShippingLoadDetailView(order: order)
            } label: {
                card
            }
            .buttonStyle(.plain)
        case .shipped:
            card
        }
    }
    
    private var foundationNotice: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(DockWalkTheme.accent)
                    Text("Outbound foundation — stable local data")
                        .font(DockWalkTheme.bodyFont.weight(.semibold))
                }
                Text("Pick, stage, load workflow structure ready. Full outbound write operations, inventory decrement, and label/BOL generation will expand in a later release.")
                    .font(DockWalkTheme.captionFont)
                    .foregroundStyle(DockWalkTheme.textSecondary)
            }
        }
    }
}

#Preview {
    ShippingHomeView()
        .environment(ScannerPreferencesStore.shared)
}
