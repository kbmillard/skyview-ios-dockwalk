import XCTest
@testable import DockWalk

final class DockWalkFoundationTests: XCTestCase {
    func testReceivingAppointmentStubCount() {
        let viewModel = AppointmentsViewModel()
        XCTAssertEqual(viewModel.appointments.count, 4)
    }

    func testInventoryFilterBySKU() {
        let viewModel = InventoryViewModel()
        viewModel.searchQuery = "99201"
        XCTAssertEqual(viewModel.filteredItems.count, 1)
        XCTAssertEqual(viewModel.filteredItems.first?.sku, "SKU-99201")
    }

    func testFeatureFlagsDefaults() {
        XCTAssertFalse(FeatureFlags.aiInspectionEnabled)
        XCTAssertFalse(FeatureFlags.paymentsEnabled)
        XCTAssertFalse(FeatureFlags.liveScannerEnabled)
        XCTAssertTrue(FeatureFlags.offlineSyncEnabled)
    }

    func testOfflineSyncEnqueue() {
        let store = OfflineSyncStore.shared
        store.clearQueue()
        store.enqueue(kind: "test", summary: "Demo action")
        if case .pending(let count) = store.status {
            XCTAssertEqual(count, 1)
        } else {
            XCTFail("Expected pending status")
        }
    }
}
