import Foundation
import Observation

@Observable
final class OfflineSyncStore {
    static let shared = OfflineSyncStore()

    private(set) var queuedActions: [QueuedSyncAction] = []
    var status: SyncStatus = .online

    init(loadPersisted: Bool = true) {
        if loadPersisted {
            queuedActions = SyncQueuePersistence.load()
        }
        refreshStatus()
    }

    func enqueue(kind: String, summary: String) {
        guard FeatureFlags.offlineSyncEnabled else { return }
        let action = QueuedSyncAction(
            id: UUID(),
            kind: kind,
            summary: summary,
            createdAt: Date()
        )
        queuedActions.append(action)
        persist()
        refreshStatus()
    }

    func clearQueue() {
        queuedActions.removeAll()
        persist()
        refreshStatus()
    }

    func markSyncing() {
        status = .syncing
    }

    func markFailed(_ message: String) {
        status = .failed(message: message)
    }

    func markOnline() {
        refreshStatus()
    }

    func markOffline() {
        status = .offline
    }

    private func persist() {
        _ = SyncQueuePersistence.save(queuedActions)
    }

    private func refreshStatus() {
        if queuedActions.isEmpty {
            status = .online
        } else {
            status = .pending(count: queuedActions.count)
        }
    }
}
