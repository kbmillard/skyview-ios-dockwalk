import Foundation

enum SyncBatchReplayEngine {
    static let maxBatchSize = 50

    static func replay(
        actions: [QueuedSyncAction],
        postBatch: (SyncBatchEnvelope) async throws -> SyncBatchResponse
    ) async -> ReceivingEventReplayOutcome {
        let pending = ReceivingEventReplayEngine.pendingReceivingActions(from: actions)
        guard !pending.isEmpty else {
            return ReceivingEventReplayOutcome(succeeded: 0, failed: 0, removedActionIDs: [])
        }

        var succeeded = 0
        var failed = 0
        var removed: [UUID] = []
        var remaining = pending

        while !remaining.isEmpty {
            let chunk = Array(remaining.prefix(maxBatchSize))
            let requests = chunk.compactMap(\.receivingEventPayload)
            guard !requests.isEmpty else { break }

            let envelope = SyncBatchEnvelope(
                orgId: requests[0].orgId,
                facilityId: requests[0].facilityId,
                deviceId: requests[0].deviceId,
                requests: requests
            )

            do {
                let response = try await postBatch(envelope)
                let resultByKey = Dictionary(
                    uniqueKeysWithValues: response.results.map { ($0.idempotencyKey, $0) }
                )

                for action in chunk {
                    guard let payload = action.receivingEventPayload,
                          let result = resultByKey[payload.idempotencyKey] else {
                        failed += 1
                        continue
                    }
                    if result.isSuccess {
                        removed.append(action.id)
                        succeeded += 1
                    } else {
                        failed += 1
                    }
                }
            } catch {
                failed += chunk.count
            }

            remaining = Array(remaining.dropFirst(chunk.count))
        }

        return ReceivingEventReplayOutcome(
            succeeded: succeeded,
            failed: failed,
            removedActionIDs: removed
        )
    }
}
