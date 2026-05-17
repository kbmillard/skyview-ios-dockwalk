import SwiftUI

struct ShippingHomeView: View {
    @State private var viewModel = OutboundViewModel()
    @State private var showScanner = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DockWalkTheme.sectionSpacing) {
                    outboundSummary
                    PrimaryActionButton(title: "Scan Load", systemImage: "barcode.viewfinder") {
                        showScanner = true
                    }
                    stagedOrdersSection
                    closeoutPlaceholder
                }
                .padding(DockWalkTheme.screenPadding)
            }
            .background(DockWalkTheme.background)
            .navigationTitle("Ship")
            .sheet(isPresented: $showScanner) {
                ScannerPlaceholderView()
            }
        }
    }

    private var outboundSummary: some View {
        HStack(spacing: 12) {
            SectionCard {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Active loads")
                        .font(DockWalkTheme.captionFont)
                        .foregroundStyle(DockWalkTheme.textSecondary)
                    Text("\(viewModel.activeLoads)")
                        .font(.system(size: 32, weight: .semibold, design: .rounded))
                }
            }
            SectionCard {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Staged orders")
                        .font(DockWalkTheme.captionFont)
                        .foregroundStyle(DockWalkTheme.textSecondary)
                    Text("\(viewModel.stagedOrders.count)")
                        .font(.system(size: 32, weight: .semibold, design: .rounded))
                }
            }
        }
    }

    private var stagedOrdersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Staged orders")
                .font(DockWalkTheme.headlineFont)
            ForEach(viewModel.stagedOrders) { order in
                SectionCard {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(order.customer)
                                .font(DockWalkTheme.headlineFont)
                            Label(order.door, systemImage: "door.right.hand.open")
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

    private var closeoutPlaceholder: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("Closeout")
                    .font(DockWalkTheme.headlineFont)
                Text("End-of-shift trailer verification and BOL sign-off will live here. Stub only in foundation build.")
                    .font(DockWalkTheme.bodyFont)
                    .foregroundStyle(DockWalkTheme.textSecondary)
            }
        }
    }
}

#Preview {
    ShippingHomeView()
}
