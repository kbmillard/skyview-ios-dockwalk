import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            TodayView()
                .tabItem {
                    Label("Today", systemImage: "sun.max.fill")
                }

            AppointmentsView()
                .tabItem {
                    Label("Receive", systemImage: "arrow.down.to.line")
                }

            ShippingHomeView()
                .tabItem {
                    Label("Ship", systemImage: "arrow.up.to.line")
                }

            InventoryHomeView()
                .tabItem {
                    Label("Inventory", systemImage: "shippingbox.fill")
                }

            SettingsView()
                .tabItem {
                    Label("More", systemImage: "ellipsis.circle.fill")
                }
        }
        .tint(DockWalkTheme.accent)
    }
}

#Preview {
    MainTabView()
        .environment(AppEnvironment.shared)
        .environment(OfflineSyncStore.shared)
        .environment(ReceivingEventReplayCoordinator.shared)
}
