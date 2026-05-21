import SwiftUI

/// DockWalk by SkyView — root tab bar.
///
/// Tab order: Today · Inbound · Inventory · Putaway · Picking · Shipping
///
/// Putaway and Picking have the most users (40+ floor workers vs 5 receivers).
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

                PutawayTabRootView()
                    .tabItem {
                        Label("Putaway", systemImage: "arrow.down.to.line.compact")
                    }
                    .tag(AppTab.putaway)

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

            // Floating scan disc above the tab bar.
            // Opens inventory lookup from any tab.
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
            selectedTab = .inventory
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
