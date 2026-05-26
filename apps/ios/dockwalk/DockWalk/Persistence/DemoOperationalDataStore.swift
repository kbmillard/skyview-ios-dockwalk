import Foundation
import Observation

/// Per-device toggle for local inbound demo queue (30 scheduled loads + foundation dock doors).
@Observable
final class DemoOperationalDataStore {
    static let shared = DemoOperationalDataStore()

    private static let userDefaultsKey = "SkyView.dockwalkFoundationInboundDemo"
    private static let hasSetDefaultKey = "SkyView.dockwalkFoundationInboundDemoDefaulted"
    /// Bump when QA default should roll out to existing installs (e.g. enable 30-load demo).
    private static let defaultPolicyVersionKey = "SkyView.dockwalkFoundationInboundDemoPolicyVersion"
    private static let currentDefaultPolicyVersion = 2

    private let defaults: UserDefaults

    private(set) var revision = 0

    var useFoundationInboundDemo: Bool {
        didSet {
            guard oldValue != useFoundationInboundDemo else { return }
            defaults.set(useFoundationInboundDemo, forKey: Self.userDefaultsKey)
            revision += 1
        }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        #if DEBUG
        let defaultEnabled = true
        if !defaults.bool(forKey: Self.hasSetDefaultKey) {
            defaults.set(defaultEnabled, forKey: Self.userDefaultsKey)
            defaults.set(true, forKey: Self.hasSetDefaultKey)
        }
        if defaults.integer(forKey: Self.defaultPolicyVersionKey) < Self.currentDefaultPolicyVersion {
            defaults.set(defaultEnabled, forKey: Self.userDefaultsKey)
            defaults.set(Self.currentDefaultPolicyVersion, forKey: Self.defaultPolicyVersionKey)
        }
        #else
        defaults.set(false, forKey: Self.userDefaultsKey)
        #endif
        self.useFoundationInboundDemo = defaults.bool(forKey: Self.userDefaultsKey)
    }
}
