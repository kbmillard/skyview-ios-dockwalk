import Foundation
import Observation

@Observable
final class SyncPreferencesStore {
    static let shared = SyncPreferencesStore()

    private static let receivingEventAutoReplayKey = "DockWalk.receivingEventAutoReplayEnabled"

    private let defaults: UserDefaults

    private(set) var revision = 0

    var receivingEventAutoReplayEnabled: Bool {
        didSet {
            guard oldValue != receivingEventAutoReplayEnabled else { return }
            persistReceivingEventAutoReplay()
            revision += 1
        }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.receivingEventAutoReplayEnabled = Self.loadReceivingEventAutoReplayEnabled(using: defaults)
    }

    static func loadReceivingEventAutoReplayEnabled(using defaults: UserDefaults = .standard) -> Bool {
        guard defaults.object(forKey: receivingEventAutoReplayKey) != nil else {
            return false
        }
        return defaults.bool(forKey: receivingEventAutoReplayKey)
    }

    func setReceivingEventAutoReplayEnabled(_ enabled: Bool) {
        receivingEventAutoReplayEnabled = enabled
    }

    private func persistReceivingEventAutoReplay() {
        defaults.set(receivingEventAutoReplayEnabled, forKey: Self.receivingEventAutoReplayKey)
    }
}
