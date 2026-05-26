import Foundation

enum PutawayCardResolver {
    /// Resolves a scanned UPC to one inventory card (receive session first, then catalog).
    static func resolve(
        upc raw: String,
        inboundSession: InboundSessionStore = .shared,
        catalog: InventoryCatalogStore = .shared,
        completionStore: PutawayCompletionStore = .shared,
        inboundShipmentId: String? = nil
    ) -> PutawayUPCCard? {
        let code = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !code.isEmpty else { return nil }

        let loadIds: [String]
        if let inboundShipmentId {
            loadIds = [inboundShipmentId]
        } else {
            loadIds = inboundSession.loadIdsWithReceivedItems()
        }

        for loadId in loadIds {
            for draft in inboundSession.receivedItems(for: loadId) {
                guard draft.isSaved,
                      draft.upc.trimmingCharacters(in: .whitespacesAndNewlines)
                          .compare(code, options: .caseInsensitive) == .orderedSame,
                      let card = PutawayUPCCard.from(receive: draft, shipmentId: loadId),
                      !completionStore.isCompleted(cardId: card.id) else { continue }
                return card
            }
        }

        if let item = catalog.item(matchingUPC: code),
           let card = PutawayUPCCard.from(catalog: item, shipmentId: inboundShipmentId),
           !completionStore.isCompleted(cardId: card.id) {
            return card
        }

        return nil
    }
}
