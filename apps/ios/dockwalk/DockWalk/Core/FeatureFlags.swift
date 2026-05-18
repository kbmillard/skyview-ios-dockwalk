import Foundation

enum FeatureFlags {
    static let aiInspectionEnabled = false
    static let paymentsEnabled = false
    /// AVFoundation barcode lab + optional Receive/Putaway scan entry points. Default **off** for TestFlight/operators.
    static let liveScannerEnabled = false
    static let offlineSyncEnabled = true
    /// Product gate — runtime toggle in More → Sync controls on-device behavior (no rebuild).
    static let receivingEventAutoReplayAvailable = true
    /// Use `POST /api/sync/events` for offline replay (receiving events + task_action).
    static let syncBatchReplayEnabled = true
    static let debugPanelEnabled = true

    static var isReceivingEventAutoReplayPermitted: Bool {
        offlineSyncEnabled && receivingEventAutoReplayAvailable
    }
}
