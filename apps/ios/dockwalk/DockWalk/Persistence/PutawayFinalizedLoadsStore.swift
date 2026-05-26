import Foundation
import Observation

/// Load ids that have been finalized and whose UPC lines are eligible for the global putaway queue.
@Observable
final class PutawayFinalizedLoadsStore {
    static let shared = PutawayFinalizedLoadsStore()

    private static let persistenceKey = "SkyView.putawayFinalizedLoadIds"

    private(set) var revision = 0
    private var finalizedLoadIds: Set<String> = []

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        load()
    }

    func markFinalized(loadId: String) {
        guard finalizedLoadIds.insert(loadId).inserted else { return }
        persist()
        bumpRevision()
    }

    func isFinalized(loadId: String) -> Bool {
        finalizedLoadIds.contains(loadId)
    }

    func allFinalizedLoadIds() -> Set<String> {
        finalizedLoadIds
    }

    private func load() {
        if let stored = defaults.stringArray(forKey: Self.persistenceKey) {
            finalizedLoadIds = Set(stored)
        }
    }

    private func persist() {
        defaults.set(Array(finalizedLoadIds), forKey: Self.persistenceKey)
    }

    private func bumpRevision() {
        revision &+= 1
    }
}
