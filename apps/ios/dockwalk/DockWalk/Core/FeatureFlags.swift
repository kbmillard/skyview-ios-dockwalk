import Foundation

enum FeatureFlags {
    static let aiInspectionEnabled = false
    static let paymentsEnabled = false
    static let liveScannerEnabled = false
    static let offlineSyncEnabled = true
    /// When true, queued receiving events replay after health/connectivity (throttled).
    static let autoReplayReceivingEventsEnabled = false
    static let debugPanelEnabled = true
}
