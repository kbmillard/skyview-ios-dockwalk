import XCTest
@testable import DockWalk

final class PutawaySessionTests: XCTestCase {
    private func makeTask(
        id: String = "PUT-1",
        sku: String = "SKU-100200",
        from: String = "RECV-STAGE",
        to: String = "A-12-03"
    ) -> PutawayTaskItem {
        PutawayTaskItem(
            id: id,
            sku: sku,
            description: "Demo",
            quantity: 24,
            uom: "EA",
            status: .pending,
            fromLocationCode: from,
            toLocationCode: to,
            inboundShipmentId: "T-4401",
            createdAt: nil
        )
    }

    func testSaveDraftReplacesPriorSavedForSameStep() {
        let store = PutawaySessionStore()
        var first = PutawayConfirmDraft.fromScan(taskId: "PUT-1", step: .toLocation, value: "WRONG")
        store.appendDraft(first)
        XCTAssertTrue(store.saveDraft(first))

        var second = PutawayConfirmDraft.fromScan(taskId: "PUT-1", step: .toLocation, value: "A-12-03")
        store.appendDraft(second)
        XCTAssertTrue(store.saveDraft(second))

        let saved = store.savedDrafts(for: "PUT-1").filter { $0.step == .toLocation }
        XCTAssertEqual(saved.count, 1)
        XCTAssertEqual(saved.first?.scannedValue, "A-12-03")
    }

    func testHubCanCompleteRequiresToAndQty() {
        let store = PutawaySessionStore()
        let task = makeTask()
        let hub = PutawayTaskHubViewModel(taskId: task.id, sessionStore: store)

        XCTAssertFalse(hub.canComplete(for: task))

        var toDraft = PutawayConfirmDraft.fromScan(taskId: task.id, step: .toLocation, value: "a-12-03")
        store.appendDraft(toDraft)
        _ = store.saveDraft(toDraft)
        XCTAssertFalse(hub.canComplete(for: task))

        var qtyDraft = PutawayConfirmDraft.empty(taskId: task.id, step: .quantity)
        qtyDraft.confirmedQty = 24
        qtyDraft.scannedValue = "24 EA"
        store.appendDraft(qtyDraft)
        _ = store.saveDraft(qtyDraft)
        XCTAssertTrue(hub.canComplete(for: task))
    }

    func testHubCanCompleteRejectsMismatchedToLocation() {
        let store = PutawaySessionStore()
        let task = makeTask()
        let hub = PutawayTaskHubViewModel(taskId: task.id, sessionStore: store)

        var wrongTo = PutawayConfirmDraft.fromScan(taskId: task.id, step: .toLocation, value: "B-99-99")
        store.appendDraft(wrongTo)
        _ = store.saveDraft(wrongTo)

        var qtyDraft = PutawayConfirmDraft.empty(taskId: task.id, step: .quantity)
        qtyDraft.confirmedQty = 24
        store.appendDraft(qtyDraft)
        _ = store.saveDraft(qtyDraft)

        XCTAssertFalse(hub.canComplete(for: task))
    }

    func testFoundationDemoSeedsAreScopedToShipment() {
        let seeds = FoundationOperationalData.putawayTasks(
            filteredBy: "T-4410",
            status: .all
        )
        XCTAssertFalse(seeds.isEmpty)
        XCTAssertTrue(seeds.allSatisfy { $0.inboundShipmentId == "T-4410" })
    }
}
