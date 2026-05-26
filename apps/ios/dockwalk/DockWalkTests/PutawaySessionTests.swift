import XCTest
@testable import DockWalk

final class PutawaySessionTests: XCTestCase {
    private func makeCard(
        id: String = "line-1",
        upc: String = "012345678901",
        sku: String = "SKU-100200",
        from: String = "RECV-STAGE",
        to: String = ""
    ) -> PutawayUPCCard {
        PutawayUPCCard(
            id: id,
            upc: upc,
            sku: sku,
            itemName: "Widget",
            partDescription: "",
            quantity: 24,
            quantityDisplay: "24 EA",
            uom: "EA",
            fromLocationCode: from,
            toLocationCode: to,
            inboundShipmentId: "T-4401",
            status: .pending,
            source: .receiveSession,
            createdAt: nil,
            apiTaskId: nil
        )
    }

    func testSaveDraftReplacesPriorSavedForSameStep() {
        let store = PutawaySessionStore()
        var first = PutawayConfirmDraft.fromScan(taskId: "line-1", step: .toLocation, value: "WRONG")
        store.appendDraft(first)
        XCTAssertTrue(store.saveDraft(first))

        var second = PutawayConfirmDraft.fromScan(taskId: "line-1", step: .toLocation, value: "A-12-03")
        store.appendDraft(second)
        XCTAssertTrue(store.saveDraft(second))

        let saved = store.savedDrafts(for: "line-1").filter { $0.step == .toLocation }
        XCTAssertEqual(saved.count, 1)
        XCTAssertEqual(saved.first?.scannedValue, "A-12-03")
    }

    func testHubCanCompleteRequiresUPCToAndQty() {
        let store = PutawaySessionStore()
        let card = makeCard()
        let hub = PutawayTaskHubViewModel(cardId: card.id, sessionStore: store)

        XCTAssertFalse(hub.canComplete(for: card))

        var upcDraft = PutawayConfirmDraft.fromScan(taskId: card.id, step: .upc, value: card.upc)
        store.appendDraft(upcDraft)
        _ = store.saveDraft(upcDraft)
        XCTAssertFalse(hub.canComplete(for: card))

        var toDraft = PutawayConfirmDraft.fromScan(taskId: card.id, step: .toLocation, value: "A-12-03")
        store.appendDraft(toDraft)
        _ = store.saveDraft(toDraft)
        XCTAssertFalse(hub.canComplete(for: card))

        var qtyDraft = PutawayConfirmDraft.empty(taskId: card.id, step: .quantity)
        qtyDraft.confirmedQty = 24
        store.appendDraft(qtyDraft)
        _ = store.saveDraft(qtyDraft)
        XCTAssertTrue(hub.canComplete(for: card))
    }

    func testMovementWaitsForFinalizeWhenQueuedAfter() async {
        let store = OfflineSyncStore(loadPersisted: false)
        let finalizePayload = InboundFinalizeRequest(
            idempotencyKey: "f1",
            facilityId: "fac",
            lines: [
                InboundFinalizeLine(
                    clientLineId: "line-1",
                    upc: "012345678901",
                    sku: "SKU-1",
                    isUnregisteredUPC: false,
                    cases: 1,
                    eachesPerCase: 1,
                    locationCode: "RECV-STAGE",
                    status: "available"
                )
            ]
        )
        store.enqueueFinalizeLoad(loadId: "T-4401", payload: finalizePayload, summary: "Finalize")
        store.enqueueInventoryMovement(
            payload: InventoryMovementRequest(
                idempotencyKey: "m1",
                facilityId: "fac",
                movementType: "putaway",
                upc: "012345678901",
                fromLocationCode: "RECV-STAGE",
                toLocationCode: "A-12-03",
                quantity: 1,
                uom: "EA",
                inboundLoadId: "T-4401",
                clientLineId: "line-1"
            ),
            loadId: "T-4401",
            clientLineId: "line-1",
            summary: "Move"
        )
        let fifo = SyncFIFOReplayEngine.fifoActions(from: store.queuedActions)
        XCTAssertEqual(fifo.count, 2)
    }
}
