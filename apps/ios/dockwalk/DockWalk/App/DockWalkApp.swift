import SwiftUI

@main
struct DockWalkApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @State private var environment = AppEnvironment.shared
    @State private var syncStore = OfflineSyncStore.shared
    @State private var syncPreferences = SyncPreferencesStore.shared
    @State private var scannerPreferences = ScannerPreferencesStore.shared
    @State private var demoOperationalData = DemoOperationalDataStore.shared
    @State private var inboundSession = InboundSessionStore.shared
    @State private var appointmentsViewModel = AppointmentsViewModel()
    @State private var replayCoordinator = ReceivingEventReplayCoordinator.shared

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environment(environment)
                .environment(syncStore)
                .environment(syncPreferences)
                .environment(scannerPreferences)
                .environment(demoOperationalData)
                .environment(inboundSession)
                .environment(appointmentsViewModel)
                .environment(replayCoordinator)
                .onChange(of: scenePhase) { _, phase in
                    guard phase == .active else { return }
                    Task {
                        await replayCoordinator.attemptAutoReplayIfNeeded(
                            environment: environment,
                            syncStore: syncStore,
                            trigger: "foreground"
                        )
                    }
                }
        }
    }
}
