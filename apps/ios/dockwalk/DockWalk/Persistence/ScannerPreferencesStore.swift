import Foundation
import Observation

/// Per-device scanner QA toggle. Compile-time `FeatureFlags.liveScannerEnabled` stays **off** for TestFlight.
@Observable
final class ScannerPreferencesStore {
    static let shared = ScannerPreferencesStore()

    private static let internalScannerKey = "DockWalk.internalScannerEnabled"

    private let defaults: UserDefaults

    private(set) var revision = 0

    /// Runtime internal toggle (Debug panel). Not shown to normal operators unless enabled here.
    var internalScannerEnabled: Bool {
        didSet {
            guard oldValue != internalScannerEnabled else { return }
            persistInternalScanner()
            revision += 1
        }
    }

    /// Scanner UI and capture flows when compile-time flag is on **or** internal toggle is on.
    var isScannerActive: Bool {
        FeatureFlags.liveScannerEnabled || internalScannerEnabled
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.internalScannerEnabled = Self.loadInternalScannerEnabled(using: defaults)
    }

    static func loadInternalScannerEnabled(using defaults: UserDefaults = .standard) -> Bool {
        guard defaults.object(forKey: internalScannerKey) != nil else {
            return false
        }
        return defaults.bool(forKey: internalScannerKey)
    }

    func setInternalScannerEnabled(_ enabled: Bool) {
        internalScannerEnabled = enabled
    }

    private func persistInternalScanner() {
        defaults.set(internalScannerEnabled, forKey: Self.internalScannerKey)
    }
}
