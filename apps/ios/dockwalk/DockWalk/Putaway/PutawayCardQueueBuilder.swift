import Foundation

/// Builds pending UPC putaway cards from receive session, catalog, and API.
enum PutawayCardQueueBuilder {
    static func pendingCards(
        inboundShipmentId: String?,
        inboundSession: InboundSessionStore,
        completionStore: PutawayCompletionStore,
        finalizedLoadIds: Set<String>? = nil
    ) -> [PutawayUPCCard] {
        var cards: [PutawayUPCCard] = []
        var seenKeys: Set<String> = []

        let loadIds: [String]
        if let inboundShipmentId {
            loadIds = [inboundShipmentId]
        } else {
            loadIds = inboundSession.loadIdsWithReceivedItems()
        }

        for loadId in loadIds {
            if let finalizedLoadIds, !finalizedLoadIds.contains(loadId) { continue }
            for draft in inboundSession.receivedItems(for: loadId) {
                guard let card = PutawayUPCCard.from(receive: draft, shipmentId: loadId),
                      !completionStore.isCompleted(cardId: card.id) else { continue }
                let key = dedupeKey(upc: card.upc, shipmentId: loadId)
                guard !seenKeys.contains(key) else { continue }
                seenKeys.insert(key)
                cards.append(card)
            }
        }

        return cards.sorted { $0.upc.localizedStandardCompare($1.upc) == .orderedAscending }
    }

    static func mergeAPI(
        _ apiCards: [PutawayUPCCard],
        into sessionCards: [PutawayUPCCard],
        completionStore: PutawayCompletionStore
    ) -> [PutawayUPCCard] {
        var result = sessionCards
        var keys = Set(sessionCards.map { dedupeKey(upc: $0.upc, shipmentId: $0.inboundShipmentId) })

        for card in apiCards where !completionStore.isCompleted(cardId: card.id) {
            let key = dedupeKey(upc: card.upc, shipmentId: card.inboundShipmentId)
            if keys.contains(key) { continue }
            keys.insert(key)
            result.append(card)
        }

        return result.sorted { $0.upc.localizedStandardCompare($1.upc) == .orderedAscending }
    }

    static func dedupeKey(upc: String, shipmentId: String?) -> String {
        "\(shipmentId ?? "global")|\(upc.lowercased())"
    }
}
