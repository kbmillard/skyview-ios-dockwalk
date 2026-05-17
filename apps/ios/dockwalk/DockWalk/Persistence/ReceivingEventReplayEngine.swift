import Foundation

struct ReceivingEventReplayOutcome: Equatable {
    let succeeded: Int
    let failed: Int
    let removedActionIDs: [UUID]
}

enum ReceivingEventReplayEngine {
    static func pendingReceivingActions(from actions: [QueuedSyncAction]) -> [QueuedSyncAction] {
        actions.filter { $0.kind == OfflineSyncStore.receivingEventKind && $0.receivingEventPayload != nil }
    }

    static func isSuccessfulResponse(_ response: ReceivingEventResponse) -> Bool {
        response.isSuccess
    }

    static func replay(
        actions: [QueuedSyncAction],
        post: (CreateReceivingEventRequest) async throws -> ReceivingEventResponse
    ) async -> ReceivingEventReplayOutcome {
        let pending = pendingReceivingActions(from: actions)
        guard !pending.isEmpty else {
            return ReceivingEventReplayOutcome(succeeded: 0, failed: 0, removedActionIDs: [])
        }

        var succeeded = 0
        var failed = 0
        var removed: [UUID] = []

        for action in pending {
            guard let payload = action.receivingEventPayload else { continue }
            do {
                let response = try await post(payload)
                if isSuccessfulResponse(response) {
                    removed.append(action.id)
                    succeeded += 1
                } else {
                    failed += 1
                }
            } catch {
                failed += 1
            }
        }

        return ReceivingEventReplayOutcome(
            succeeded: succeeded,
            failed: failed,
            removedActionIDs: removed
        )
    }
}
