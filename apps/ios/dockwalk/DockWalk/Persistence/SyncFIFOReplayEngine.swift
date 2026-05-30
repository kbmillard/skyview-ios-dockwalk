import Foundation

/// FIFO replay for finalize + inventory movement (movement after finalize per line).
enum SyncFIFOReplayEngine {
    private static func lineKey(loadId: String, clientLineId: String) -> String {
        "\(loadId)|\(clientLineId)"
    }

    static func fifoActions(from actions: [QueuedSyncAction]) -> [QueuedSyncAction] {
        actions.filter {
            ($0.kind == OfflineSyncStore.appointmentUpdateKind && $0.appointmentUpdatePayload != nil)
                || ($0.kind == OfflineSyncStore.finalizeLoadKind && $0.finalizePayload != nil)
                || ($0.kind == OfflineSyncStore.inventoryMovementKind && $0.movementPayload != nil)
                || ($0.kind == OfflineSyncStore.outboundTransitionKind && $0.outboundTransitionPayload != nil)
        }
    }

    static func replay(
        actions: [QueuedSyncAction],
        apiClient: APIClient
    ) async -> ReceivingEventReplayOutcome {
        var succeeded = 0
        var failed = 0
        var removed: [UUID] = []
        var finalizedLineKeys: Set<String> = []

        for action in actions {
            switch action.kind {
            case OfflineSyncStore.appointmentUpdateKind:
                guard let payload = action.appointmentUpdatePayload,
                      let appointmentId = action.appointmentId,
                      let orgId = action.orgId else { continue }
                do {
                    _ = try await apiClient.updateAppointment(
                        id: appointmentId,
                        orgId: orgId,
                        body: payload
                    )
                    removed.append(action.id)
                    succeeded += 1
                } catch {
                    failed += 1
                }

            case OfflineSyncStore.finalizeLoadKind:
                guard let payload = action.finalizePayload,
                      let loadId = action.inboundLoadId else { continue }
                do {
                    try await apiClient.finalizeInboundLoad(loadId: loadId, body: payload)
                    for line in payload.lines {
                        finalizedLineKeys.insert(lineKey(loadId: loadId, clientLineId: line.clientLineId))
                    }
                    removed.append(action.id)
                    succeeded += 1
                } catch {
                    failed += 1
                }

            case OfflineSyncStore.inventoryMovementKind:
                guard let payload = action.movementPayload else { continue }
                guard movementIsReady(action, in: actions, finalizedLineKeys: finalizedLineKeys) else {
                    continue
                }
                do {
                    try await apiClient.postInventoryMovement(payload)
                    removed.append(action.id)
                    succeeded += 1
                } catch {
                    failed += 1
                }

            case OfflineSyncStore.outboundTransitionKind:
                guard let payload = action.outboundTransitionPayload,
                      let orderId = action.outboundOrderId else { continue }
                guard outboundTransitionIsReady(action, in: actions) else { continue }
                do {
                    _ = try await apiClient.transitionOutboundOrder(orderId: orderId, body: payload)
                    removed.append(action.id)
                    succeeded += 1
                } catch {
                    failed += 1
                }

            default:
                continue
            }
        }

        return ReceivingEventReplayOutcome(succeeded: succeeded, failed: failed, removedActionIDs: removed)
    }

    private static func movementIsReady(
        _ action: QueuedSyncAction,
        in actions: [QueuedSyncAction],
        finalizedLineKeys: Set<String>
    ) -> Bool {
        guard let loadId = action.inboundLoadId,
              let clientLineId = action.clientLineId,
              !loadId.isEmpty,
              !clientLineId.isEmpty else {
            return true
        }
        let key = lineKey(loadId: loadId, clientLineId: clientLineId)
        if finalizedLineKeys.contains(key) { return true }

        let hasFinalizeForLine = actions.contains { candidate in
            candidate.kind == OfflineSyncStore.finalizeLoadKind
                && candidate.inboundLoadId == loadId
                && candidate.finalizePayload?.lines.contains(where: { $0.clientLineId == clientLineId }) == true
        }
        return !hasFinalizeForLine
    }

    private static func outboundTransitionIsReady(
        _ action: QueuedSyncAction,
        in actions: [QueuedSyncAction]
    ) -> Bool {
        guard let dependencyLoadId = action.dependencyLoadId,
              !dependencyLoadId.isEmpty else {
            return true
        }
        let hasPendingFinalize = actions.contains { candidate in
            candidate.kind == OfflineSyncStore.finalizeLoadKind
                && candidate.inboundLoadId == dependencyLoadId
                && candidate.finalizePayload != nil
        }
        return !hasPendingFinalize
    }
}
