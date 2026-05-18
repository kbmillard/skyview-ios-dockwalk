import Foundation
import Observation

/// Per-device scanner QA toggle. Compile-time `FeatureFlags.liveScannerEnabled` stays **off** for TestFlight.
@Observable
final class ScannerPreferencesStore {
    static let shared = ScannerPreferencesStore()

    private static let internalScannerKey = "DockWalk.internalScannerEnabled"
    /// When `CFBundleVersion` changes, internal scanner QA resets to **off** (TestFlight updates keep UserDefaults).
    private static let scopedBuildKey = "DockWalk.internalScannerScopedBuild"

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

    init(defaults: UserDefaults = .standard, bundleVersion: String? = nil) {
        self.defaults = defaults
        let build = bundleVersion ?? (Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "0")
        Self.applyBuildScopedResetIfNeeded(defaults: defaults, currentBuild: build)
        self.internalScannerEnabled = Self.loadInternalScannerEnabled(using: defaults)
    }

    /// Resets internal scanner to off on first launch of a new app build (per device).
    static func applyBuildScopedResetIfNeeded(
        defaults: UserDefaults = .standard,
        currentBuild: String = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "0"
    ) {
        guard defaults.string(forKey: scopedBuildKey) != currentBuild else { return }
        defaults.set(currentBuild, forKey: scopedBuildKey)
        defaults.set(false, forKey: internalScannerKey)
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
