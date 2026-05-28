import Foundation
import Observation

@Observable
final class OfflineSyncStore {
    static let shared = OfflineSyncStore()

    static let receivingEventKind = "inbound.receiving_event"
    static let taskActionKind = "task_action"
    static let finalizeLoadKind = "inbound.finalize_load"
    static let inventoryMovementKind = "inventory.movement"

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
        upsert(action)
    }

    func enqueueReceivingEvent(_ request: CreateReceivingEventRequest, summary: String) {
        guard FeatureFlags.offlineSyncEnabled else { return }
        let action = QueuedSyncAction(
            kind: Self.receivingEventKind,
            summary: summary,
            receivingEventPayload: request
        )
        upsert(action, idempotencyKey: request.idempotencyKey)
    }

    func enqueueTaskAction(_ payload: QueuedTaskActionPayload, summary: String) {
        guard FeatureFlags.offlineSyncEnabled else { return }
        let action = QueuedSyncAction(
            kind: Self.taskActionKind,
            summary: summary,
            taskActionPayload: payload
        )
        upsert(action, idempotencyKey: payload.idempotencyKey)
    }

    func enqueueFinalizeLoad(loadId: String, payload: InboundFinalizeRequest, summary: String) {
        guard FeatureFlags.offlineSyncEnabled else { return }
        let action = QueuedSyncAction(
            kind: Self.finalizeLoadKind,
            summary: summary,
            finalizePayload: payload,
            inboundLoadId: loadId
        )
        upsert(action, idempotencyKey: payload.idempotencyKey)
    }

    func enqueueInventoryMovement(
        payload: InventoryMovementRequest,
        loadId: String?,
        clientLineId: String,
        summary: String
    ) {
        guard FeatureFlags.offlineSyncEnabled else { return }
        let action = QueuedSyncAction(
            kind: Self.inventoryMovementKind,
            summary: summary,
            movementPayload: payload,
            inboundLoadId: loadId,
            clientLineId: clientLineId
        )
        upsert(action, idempotencyKey: payload.idempotencyKey)
    }

    /// Replace an existing row with the same idempotency key instead of piling duplicates.
    private func upsert(_ action: QueuedSyncAction, idempotencyKey: String? = nil) {
        if let key = idempotencyKey?.trimmingCharacters(in: .whitespacesAndNewlines), !key.isEmpty,
           let index = queuedActions.firstIndex(where: { existing in
               existingIdempotencyKey(existing) == key
           }) {
            var merged = action
            merged.lastError = queuedActions[index].lastError
            queuedActions[index] = merged
        } else if let movementKey = movementCoalesceKey(for: action),
                  let index = queuedActions.firstIndex(where: { movementCoalesceKey(for: $0) == movementKey }) {
            queuedActions[index] = action
        } else {
            queuedActions.append(action)
        }
        persist()
        refreshStatus()
        lastReplayMessage = pendingSyncableCount > 0
            ? "\(pendingSyncableCount) action(s) waiting to sync"
            : nil
    }

    private func existingIdempotencyKey(_ action: QueuedSyncAction) -> String? {
        switch action.kind {
        case Self.receivingEventKind:
            return action.receivingEventPayload?.idempotencyKey
        case Self.taskActionKind:
            return action.taskActionPayload?.idempotencyKey
        case Self.finalizeLoadKind:
            return action.finalizePayload?.idempotencyKey
        case Self.inventoryMovementKind:
            return action.movementPayload?.idempotencyKey
        default:
            return nil
        }
    }

    private func movementCoalesceKey(for action: QueuedSyncAction) -> String? {
        guard action.kind == Self.inventoryMovementKind,
              let payload = action.movementPayload else { return nil }
        return "\(payload.idempotencyKey)|\(action.inboundLoadId ?? "")|\(action.clientLineId ?? "")"
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
