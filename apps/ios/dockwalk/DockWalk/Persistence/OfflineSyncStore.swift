import Foundation
import Observation

@Observable
final class OfflineSyncStore {
    static let shared = OfflineSyncStore()

    static let receivingEventKind = "inbound.receiving_event"
    static let taskActionKind = "task_action"

    private(set) var queuedActions: [QueuedSyncAction] = []
    var status: SyncStatus = .online
    private(set) var lastReplayMessage: String?

    init(loadPersisted: Bool = true) {
        if loadPersisted {
            queuedActions = SyncQueuePersistence.load()
        }
        refreshStatus()
    }

    func enqueue(kind: String, summary: String) {
        guard FeatureFlags.offlineSyncEnabled else { return }
        let action = QueuedSyncAction(kind: kind, summary: summary)
        queuedActions.append(action)
        persist()
        refreshStatus()
    }

    func enqueueReceivingEvent(_ request: CreateReceivingEventRequest, summary: String) {
        guard FeatureFlags.offlineSyncEnabled else { return }
        let action = QueuedSyncAction(
            kind: Self.receivingEventKind,
            summary: summary,
            receivingEventPayload: request
        )
        queuedActions.append(action)
        persist()
        refreshStatus()
    }

    func enqueueTaskAction(_ payload: QueuedTaskActionPayload, summary: String) {
        guard FeatureFlags.offlineSyncEnabled else { return }
        let action = QueuedSyncAction(
            kind: Self.taskActionKind,
            summary: summary,
            taskActionPayload: payload
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

    func removeQueuedActions(withIDs ids: Set<UUID>) {
        guard !ids.isEmpty else { return }
        queuedActions.removeAll { ids.contains($0.id) }
        persist()
        refreshStatus()
    }

    func applyReplayRejections(_ messagesByActionID: [UUID: String]) {
        guard !messagesByActionID.isEmpty else { return }
        for index in queuedActions.indices {
            if let message = messagesByActionID[queuedActions[index].id] {
                queuedActions[index].lastError = message
            }
        }
        persist()
    }

    func recordReplayMessage(_ message: String) {
        lastReplayMessage = message
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

    var pendingReceivingEventCount: Int {
        SyncBatchReplayEngine.pendingSyncableActions(from: queuedActions)
            .filter { $0.kind == Self.receivingEventKind }
            .count
    }

    var pendingTaskActionCount: Int {
        SyncBatchReplayEngine.pendingSyncableActions(from: queuedActions)
            .filter { $0.kind == Self.taskActionKind }
            .count
    }

    var pendingSyncableCount: Int {
        SyncBatchReplayEngine.pendingSyncableActions(from: queuedActions).count
    }

    /// Manual replay from Debug — delegates to coordinator.
    @discardableResult
    func replayReceivingEvents(using environment: AppEnvironment) async -> (succeeded: Int, failed: Int) {
        let outcome = await ReceivingEventReplayCoordinator.shared.replayReceivingEvents(
            environment: environment,
            syncStore: self,
            label: "Manual"
        )
        return (outcome.succeeded, outcome.failed)
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

enum APIClientErrorClassifier {
    static func shouldQueueOffline(for error: Error) -> Bool {
        if let apiError = error as? APIClientError {
            switch apiError {
            case .transport:
                return true
            case .httpStatus, .invalidURL, .decoding, .railwayHostUnavailable:
                return false
            }
        }
        return (error as? URLError) != nil
    }
}
