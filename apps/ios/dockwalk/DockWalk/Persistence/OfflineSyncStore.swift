import Foundation
import Observation

struct QueuedSyncAction: Identifiable, Equatable {
    let id: UUID
    let kind: String
    let summary: String
    let createdAt: Date
}

@Observable
final class OfflineSyncStore {
    static let shared = OfflineSyncStore()

    private(set) var queuedActions: [QueuedSyncAction] = []
    var status: SyncStatus = .online

    private init() {
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
        refreshStatus()
    }

    func clearQueue() {
        queuedActions.removeAll()
        refreshStatus()
    }

    func markSyncing() {
        status = .syncing
    }

    func markFailed(_ message: String) {
        status = .failed(message: message)
    }

    func markOnline() {
        status = .online
    }

    func markOffline() {
        status = .offline
    }

    private func refreshStatus() {
        if queuedActions.isEmpty {
            status = .online
        } else {
            status = .pending(count: queuedActions.count)
        }
    }
}
