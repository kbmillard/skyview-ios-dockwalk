import SwiftUI

/// DockWalk by SkyView — root tab bar.
///
/// Tab order: Today · Inbound · Inventory · Picking · Shipping
struct MainTabView: View {
    @Environment(ScannerPreferencesStore.self) private var scannerPreferences
    @Environment(InventoryScannerCoordinator.self) private var inventoryScannerCoordinator
    @Environment(ReceiveScannerCoordinator.self) private var receiveScannerCoordinator
    @State private var selectedTab: AppTab = .today

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                TodayDashboard()
                    .tabItem {
                        Label("Today", systemImage: "sun.max.fill")
                    }
                    .tag(AppTab.today)

                AppointmentsView()
                    .tabItem {
                        Label("Inbound", systemImage: "arrow.down.to.line")
                    }
                    .tag(AppTab.inbound)

                InventoryHomeView()
                    .tabItem {
                        Label("Inventory", systemImage: "shippingbox.fill")
                    }
                    .tag(AppTab.inventory)

                PickingTabRootView()
                    .tabItem {
                        Label("Picking", systemImage: "cart")
                    }
                    .tag(AppTab.picking)

                ShippingTabRootView()
                    .tabItem {
                        Label("Shipping", systemImage: "arrow.up.to.line")
                    }
                    .tag(AppTab.shipping)
            }
            .tint(Tokens.Color.Accent.horizon)
            .id(scannerPreferences.revision)

            // Floating scan disc: receive hub → scan on load; otherwise → Inventory (putaway-capable lookup).
            floatingScanDisc
                .offset(y: -58)
        }
    }

    private var floatingScanDisc: some View {
        Button {
            Haptics.scanSuccess()
            if receiveScannerCoordinator.isReceiveHubActive {
                receiveScannerCoordinator.requestOpenScanner()
            } else {
                selectedTab = .inventory
                if scannerPreferences.isScannerActive {
                    inventoryScannerCoordinator.requestOpenScanner()
                }
            }
        } label: {
            ZStack {
                Circle()
                    .fill(Tokens.Color.Accent.horizon)
                    .frame(width: 56, height: 56)
                    .shadow(
                        color: Tokens.Color.Accent.horizon.opacity(0.3),
                        radius: 8,
                        y: 3
                    )

                Image(systemName: "barcode.viewfinder")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(Tokens.Color.Ink.inverse)
            }
        }
    }
}

#Preview {
    MainTabView()
        .environment(AppEnvironment.shared)
        .environment(OfflineSyncStore.shared)
        .environment(SyncPreferencesStore.shared)
        .environment(ScannerPreferencesStore.shared)
        .environment(DemoOperationalDataStore.shared)
        .environment(InboundSessionStore.shared)
        .environment(AppointmentsViewModel())
        .environment(InventoryScannerCoordinator.shared)
        .environment(ReceiveScannerCoordinator.shared)
        .environment(PutawayCompletionStore.shared)
        .environment(InventoryCatalogStore.shared)
        .environment(FacilityConfigStore.shared)
        .environment(ReceivingEventReplayCoordinator.shared)
}
