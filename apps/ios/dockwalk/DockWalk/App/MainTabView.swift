import SwiftUI

/// DockWalk by SkyView — root tab bar.
///
/// Tab order is fixed by product spec:
///   Today · Inbound · **Inventory (center)** · Shipping
///
/// Inventory is the universal lookup hub and must remain visually centered.
/// Putaway is integrated into the Inbound tab.
struct MainTabView: View {
    @Environment(ScannerPreferencesStore.self) private var scannerPreferences
    @State private var selectedTab: AppTab = .today
    @State private var showFloatingScanner = false
    @State private var showFloatingScanConfirm = false
    @State private var showInventoryAddOptions = false
    @State private var showManualInventoryAdd = false

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
                        Label("Inbound", systemImage: "arrow.down.to.line")
                    }
                    .tag(AppTab.inbound)

                InventoryHomeView()
                    .tabItem {
                        Label("Inventory", systemImage: "shippingbox.fill")
                    }
                    .tag(AppTab.inventory)

                ShippingTabRootView()
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
            // when on Inbound / Shipping.
            floatingScanDisc
                .offset(y: -58)
        }
        .sheet(isPresented: $showFloatingScanner) {
            BarcodeScannerSheet(title: "Scan inventory") { _ in
                showFloatingScanConfirm = true
            }
        }
        .sheet(isPresented: $showFloatingScanConfirm) {
            ScanConfirmSheet(payload: MockWarehouseFloor.scanConfirmSample)
        }
        .sheet(isPresented: $showInventoryAddOptions) {
            InventoryAddOptionsSheet(
                onScanSelected: {
                    showFloatingScanner = true
                },
                onManualAddSelected: {
                    showManualInventoryAdd = true
                }
            )
        }
        .sheet(isPresented: $showManualInventoryAdd) {
            ManualInventoryAddView()
        }
        .dismissScannerSheetWhenInactive(scannerPreferences, isPresented: $showFloatingScanner)
    }

    private var floatingScanDisc: some View {
        Button {
            Haptics.scanSuccess()
            switch selectedTab {
            case .today:
                selectedTab = .inventory
            case .inventory:
                // Always show add options sheet for Inventory tab
                showInventoryAddOptions = true
            case .inbound, .shipping:
                showFloatingScanConfirm = true
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
        .environment(ReceivingEventReplayCoordinator.shared)
}
