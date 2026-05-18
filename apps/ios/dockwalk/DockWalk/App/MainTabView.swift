import SwiftUI

struct MainTabView: View {
    @Environment(ScannerPreferencesStore.self) private var scannerPreferences
    @State private var selectedTab: AppTab = .today

    var body: some View {
        TabView(selection: $selectedTab) {
            TodayView(selectedTab: $selectedTab)
                .tabItem {
                    Label("Today", systemImage: "sun.max.fill")
                }
                .tag(AppTab.today)

            AppointmentsView()
                .tabItem {
                    Label("Receive", systemImage: "arrow.down.to.line")
                }
                .tag(AppTab.receive)

            PutawayTabRootView()
                .tabItem {
                    Label("Putaway", systemImage: "arrow.left.arrow.right.square")
                }
                .tag(AppTab.putaway)

            ShippingHomeView()
                .tabItem {
                    Label("Ship", systemImage: "arrow.up.to.line")
                }
                .tag(AppTab.ship)

            SettingsView()
                .tabItem {
                    Label("More", systemImage: "ellipsis.circle.fill")
                }
                .tag(AppTab.more)
        }
        .tint(DockWalkTheme.accent)
        .id(scannerPreferences.revision)
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
