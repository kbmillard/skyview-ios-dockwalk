import Foundation

enum FeatureFlags {
    static let aiInspectionEnabled = false
    static let paymentsEnabled = false
    /// Compile-time scanner gate. Default **off** for TestFlight; per-device QA uses `ScannerPreferencesStore.internalScannerEnabled` (Debug).
    static let liveScannerEnabled = false
    static let offlineSyncEnabled = true
    /// Product gate — runtime toggle in More → Sync (DEBUG only; Release uses manual Replay now).
    #if DEBUG
    static let receivingEventAutoReplayAvailable = true
    #else
    static let receivingEventAutoReplayAvailable = false
    #endif
    /// Use `POST /api/sync/events` for offline replay (receiving events + task_action).
    static let syncBatchReplayEnabled = true
    static let debugPanelEnabled = true

    static var isReceivingEventAutoReplayPermitted: Bool {
        offlineSyncEnabled && receivingEventAutoReplayAvailable
    }

    /// DEBUG-only gate for local demo loads / foundation putaway seeds.
    #if DEBUG
    static let allowFoundationDemoData = true
    #else
    static let allowFoundationDemoData = false
    #endif

    /// Local T-4401…T-4430 inbound queue; ignores live appointment list when on (DEBUG + toggle).
    static var foundationInboundDemoEnabled: Bool {
        allowFoundationDemoData && DemoOperationalDataStore.shared.useFoundationInboundDemo
    }
}
