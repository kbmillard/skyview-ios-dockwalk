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
    @State private var inventoryScannerCoordinator = InventoryScannerCoordinator.shared
    @State private var receiveScannerCoordinator = ReceiveScannerCoordinator.shared
    @State private var putawayScannerCoordinator = PutawayScannerCoordinator.shared
    @State private var putawaySession = PutawaySessionStore.shared
    @State private var putawayCompletion = PutawayCompletionStore.shared
    @State private var putawayFinalizedLoads = PutawayFinalizedLoadsStore.shared
    @State private var facilityConfig = FacilityConfigStore.shared
    @State private var inventoryCatalog = InventoryCatalogStore.shared
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
                .environment(inventoryScannerCoordinator)
                .environment(receiveScannerCoordinator)
                .environment(putawayScannerCoordinator)
                .environment(putawaySession)
                .environment(putawayCompletion)
                .environment(putawayFinalizedLoads)
                .environment(facilityConfig)
                .environment(inventoryCatalog)
                .environment(replayCoordinator)
                .task {
                    await facilityConfig.refresh(environment: environment)
                }
                .onChange(of: environment.configRevision) { _, _ in
                    Task { await facilityConfig.refresh(environment: environment) }
                }
                .onChange(of: scenePhase) { _, phase in
                    guard phase == .active else { return }
                    #if DEBUG
                    guard syncPreferences.receivingEventAutoReplayEnabled else { return }
                    Task {
                        await replayCoordinator.attemptAutoReplayIfNeeded(
                            environment: environment,
                            syncStore: syncStore,
                            trigger: "foreground"
                        )
                    }
                    #endif
                }
        }
    }
}
