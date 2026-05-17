import Foundation

enum SyncBatchReplayEngine {
    static let maxBatchSize = 50

    static func pendingSyncableActions(from actions: [QueuedSyncAction]) -> [QueuedSyncAction] {
        actions.filter { action in
            if action.kind == OfflineSyncStore.receivingEventKind,
               action.receivingEventPayload != nil {
                return true
            }
            if action.kind == OfflineSyncStore.taskActionKind,
               action.taskActionPayload != nil {
                return true
            }
            return false
        }
    }

    static func replay(
        actions: [QueuedSyncAction],
        postBatch: (SyncBatchEnvelope) async throws -> SyncBatchResponse
    ) async -> (outcome: ReceivingEventReplayOutcome, rejectionMessages: [UUID: String]) {
        let pending = pendingSyncableActions(from: actions)
        guard !pending.isEmpty else {
            return (
                ReceivingEventReplayOutcome(succeeded: 0, failed: 0, removedActionIDs: []),
                [:]
            )
        }

        var succeeded = 0
        var failed = 0
        var removed: [UUID] = []
        var rejections: [UUID: String] = [:]
        var remaining = pending

        while !remaining.isEmpty {
            let chunk = Array(remaining.prefix(maxBatchSize))
            let records: [SyncBatchEventRecord] = chunk.compactMap { action in
                if let request = action.receivingEventPayload {
                    return .receiving(request)
                }
                if let payload = action.taskActionPayload {
                    return .taskAction(payload)
                }
                return nil
            }
            guard !records.isEmpty else { break }

            let orgId = records[0].orgId
            let facilityId = chunk.compactMap(\.receivingEventPayload?.facilityId).first
            let deviceId = chunk.compactMap(\.receivingEventPayload?.deviceId).first
                ?? chunk.compactMap(\.taskActionPayload?.deviceId).first

            let envelope = SyncBatchEnvelope(
                orgId: orgId,
                facilityId: facilityId,
                deviceId: deviceId,
                events: records
            )

            do {
                let response = try await postBatch(envelope)
                let resultByKey = Dictionary(
                    uniqueKeysWithValues: response.results.map { ($0.idempotencyKey, $0) }
                )

                for action in chunk {
                    let key = action.receivingEventPayload?.idempotencyKey
                        ?? action.taskActionPayload?.idempotencyKey
                    guard let key, let result = resultByKey[key] else {
                        failed += 1
                        continue
                    }
                    if result.isSuccess {
                        removed.append(action.id)
                        succeeded += 1
                    } else {
                        failed += 1
                        if let message = result.rejectionMessage {
                            rejections[action.id] = message
                        }
                    }
                }
            } catch {
                failed += chunk.count
            }

            remaining = Array(remaining.dropFirst(chunk.count))
        }

        return (
            ReceivingEventReplayOutcome(
                succeeded: succeeded,
                failed: failed,
                removedActionIDs: removed
            ),
            rejections
        )
    }
}
