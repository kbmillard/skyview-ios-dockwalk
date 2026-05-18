import SwiftUI

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
            .tint(Tokens.Color.Accent.horizon)
            .id(scannerPreferences.revision)
            
            // Floating scan disc above tab bar
            floatingScanDisc
                .offset(y: -58)
        }
    }
    
    private var floatingScanDisc: some View {
        Button {
            Haptics.scanSuccess()
            // TODO: Open scanner sheet
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
