import Foundation
import Observation

@Observable
final class OfflineSyncStore {
    static let shared = OfflineSyncStore()

    static let receivingEventKind = "inbound.receiving_event"

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

    var pendingReceivingEventCount: Int {
        queuedActions.filter { $0.kind == Self.receivingEventKind }.count
    }

    /// Replays only queued receiving events (narrow scope — not a full sync engine).
    @discardableResult
    func replayReceivingEvents(using environment: AppEnvironment) async -> (succeeded: Int, failed: Int) {
        let pending = queuedActions.filter { $0.kind == Self.receivingEventKind && $0.receivingEventPayload != nil }
        guard !pending.isEmpty else {
            lastReplayMessage = "No receiving events in queue."
            return (0, 0)
        }

        markSyncing()
        let client = environment.makeAPIClient()
        var succeeded = 0
        var failed = 0

        for action in pending {
            guard let payload = action.receivingEventPayload else { continue }
            do {
                let _: ReceivingEventResponse = try await client.post(.receivingEvents, body: payload)
                queuedActions.removeAll { $0.id == action.id }
                succeeded += 1
            } catch {
                failed += 1
            }
        }

        persist()
        refreshStatus()
        lastReplayMessage = "Replay: \(succeeded) sent, \(failed) still pending."
        return (succeeded, failed)
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
            case .httpStatus, .invalidURL, .decoding:
                return false
            }
        }
        return (error as? URLError) != nil
    }
}
