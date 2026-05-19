import SwiftUI

/// DockWalk by SkyView — root tab bar.
///
/// Tab order is fixed by product spec:
///   Today · Receiving · **Inventory (center)** · Putaway · Shipping
///
/// Inventory is the universal lookup hub and must remain visually centered.
struct MainTabView: View {
    @Environment(ScannerPreferencesStore.self) private var scannerPreferences
    @State private var selectedTab: AppTab = .today

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                TodayDashboard(selectedTab: $selectedTab)
                    .tabItem {
                        Label("Today", systemImage: "sun.max.fill")
                    }
                    .tag(AppTab.today)

                AppointmentsView()
                    .tabItem {
                        Label("Receiving", systemImage: "arrow.down.to.line")
                    }
                    .tag(AppTab.receiving)

                InventoryHomeView()
                    .tabItem {
                        Label("Inventory", systemImage: "shippingbox.fill")
                    }
                    .tag(AppTab.inventory)

                PutawayTabRootView()
                    .tabItem {
                        Label("Putaway", systemImage: "arrow.left.arrow.right.square")
                    }
                    .tag(AppTab.putaway)

                ShippingHomeView()
                    .tabItem {
                        Label("Shipping", systemImage: "arrow.up.to.line")
                    }
                    .tag(AppTab.shipping)
            }
            .tint(Tokens.Color.Accent.horizon)
            .id(scannerPreferences.revision)

            // Floating scan disc above the tab bar.
            // Inventory is the center tab, so this disc visually anchors the
            // global-lookup scanner when on Inventory, and the work-mode scanner
            // when on Receiving / Putaway / Shipping.
            floatingScanDisc
                .offset(y: -58)
        }
    }

    private var floatingScanDisc: some View {
        Button {
            Haptics.scanSuccess()
            // TODO: Open scanner sheet wired to current tab's ScannerMode.
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
        .environment(ReceivingEventReplayCoordinator.shared)
}
