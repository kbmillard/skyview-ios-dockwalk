import Foundation
import Observation

/// Tracks putaway-completed inventory card ids (per UPC line).
@Observable
final class PutawayCompletionStore {
    static let shared = PutawayCompletionStore()

    private static let persistenceKey = "SkyView.putawayCompletedCardIds"

    private(set) var revision = 0
    private var completedIds: Set<String> = []

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        load()
    }

    func isCompleted(cardId: String) -> Bool {
        completedIds.contains(cardId)
    }

    func markCompleted(cardId: String) {
        guard completedIds.insert(cardId).inserted else { return }
        persist()
        bumpRevision()
    }

    func clearCompleted(cardId: String) {
        guard completedIds.remove(cardId) != nil else { return }
        persist()
        bumpRevision()
    }

    func clearAll() {
        completedIds = []
        persist()
        bumpRevision()
    }

    private func load() {
        if let stored = defaults.stringArray(forKey: Self.persistenceKey) {
            completedIds = Set(stored)
        }
    }

    private func persist() {
        defaults.set(Array(completedIds), forKey: Self.persistenceKey)
    }

    private func bumpRevision() {
        revision &+= 1
    }
}
