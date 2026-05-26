import Foundation

enum PutawayMovementError: LocalizedError {
    case invalidLocation
    case syncingLocations
    case draftNotFound
    case transport(String)

    var errorDescription: String? {
        switch self {
        case .invalidLocation: return "That location is not valid for this facility."
        case .syncingLocations: return "Syncing locations… try again in a moment."
        case .draftNotFound: return "Could not find this receive line."
        case .transport(let message): return message
        }
    }
}

enum PutawayMovementService {
    static func apply(
        card: PutawayUPCCard,
        toLocation: String,
        facilityConfig: FacilityConfigStore,
        inboundSession: InboundSessionStore,
        catalog: InventoryCatalogStore,
        completionStore: PutawayCompletionStore,
        syncStore: OfflineSyncStore,
        environment: AppEnvironment
    ) async -> Result<Void, PutawayMovementError> {
        let trimmedTo = toLocation.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTo.isEmpty else { return .failure(.invalidLocation) }

        switch await facilityConfig.isValidLocation(trimmedTo, environment: environment) {
        case .valid: break
        case .syncing: return .failure(.syncingLocations)
        case .invalid: return .failure(.invalidLocation)
        }

        if card.source == .receiveSession {
            guard let loadId = card.inboundShipmentId,
                  inboundSession.updateReceivedItemLocation(loadId: loadId, itemId: card.id, location: trimmedTo) else {
                return .failure(.draftNotFound)
            }
        }

        let fromCode = card.fromLocationCode.isEmpty
            ? facilityConfig.defaultReceiveLocation()
            : card.fromLocationCode

        let payload = InventoryMovementRequest(
            idempotencyKey: UUID().uuidString,
            facilityId: environment.facilityId,
            movementType: "putaway",
            upc: card.upc,
            fromLocationCode: fromCode,
            toLocationCode: trimmedTo,
            quantity: card.quantity,
            uom: card.uom,
            inboundLoadId: card.inboundShipmentId,
            clientLineId: card.id
        )

        let client = environment.makeAPIClient()
        do {
            try await client.postInventoryMovement(payload)
        } catch {
            if APIClientErrorClassifier.shouldQueueOffline(for: error) {
                syncStore.enqueueInventoryMovement(
                    payload: payload,
                    loadId: card.inboundShipmentId,
                    clientLineId: card.id,
                    summary: "Putaway \(card.upc) → \(trimmedTo)"
                )
            } else {
                return .failure(.transport(error.localizedDescription))
            }
        }

        completionStore.markCompleted(cardId: card.id)
        PutawaySessionStore.shared.clearTask(card.id)
        return .success(())
    }
}
