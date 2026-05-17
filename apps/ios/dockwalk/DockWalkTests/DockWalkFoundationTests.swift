import XCTest
@testable import DockWalk

final class DockWalkFoundationTests: XCTestCase {
    func testAppointmentStatusMapping() {
        let dto = AppointmentDTO(
            id: "a1",
            orgId: nil,
            facilityId: nil,
            dockId: nil,
            carrierId: nil,
            referenceNumber: "PO-1",
            status: "arrived",
            scheduledAt: "2026-05-16T14:00:00Z",
            notes: nil,
            metadata: ["carrier_name": .string("SwiftLine"), "dock_name": .string("Dock 3")]
        )
        let mapped = InboundAPIMapping.mapAppointment(dto)
        XCTAssertEqual(mapped.status, .checkedIn)
        XCTAssertEqual(mapped.carrier, "SwiftLine")
        XCTAssertEqual(mapped.poNumber, "PO-1")
    }

    func testInboundShipmentFiltersByAppointment() {
        let shipment = InboundShipmentItem(
            id: "s1",
            appointmentId: "apt-1",
            referenceNumber: "ASN-9",
            status: "receiving",
            expectedAt: nil,
            receivedAt: nil
        )
        let line = InboundAPIMapping.mapShipmentToReceivedLine(shipment)
        XCTAssertEqual(line.sku, "ASN-9")
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

    func testSyncQueuePersistenceRoundTrip() {
        let prior = SyncQueuePersistence.load()
        defer { _ = SyncQueuePersistence.save(prior) }

        let action = QueuedSyncAction(id: UUID(), kind: "test", summary: "Persist me", createdAt: Date())
        XCTAssertTrue(SyncQueuePersistence.save([action]))

        let loaded = SyncQueuePersistence.load()
        XCTAssertEqual(loaded.count, 1)
        XCTAssertEqual(loaded.first?.summary, "Persist me")
    }

    func testOfflineSyncEnqueuePersists() {
        let store = OfflineSyncStore(loadPersisted: false)
        store.clearQueue()
        store.enqueue(kind: "inbound.start", summary: "PO-123")
        XCTAssertEqual(store.queuedActions.count, 1)
        if case .pending(let count) = store.status {
            XCTAssertEqual(count, 1)
        } else {
            XCTFail("Expected pending status")
        }

        let reloaded = OfflineSyncStore(loadPersisted: true)
        XCTAssertGreaterThanOrEqual(reloaded.queuedActions.count, 1)
        store.clearQueue()
    }

    func testAppointmentsEndpointIncludesOrgQuery() {
        let url = APIEndpoint.appointments(orgId: "00000000-0000-4000-8000-000000000001")
            .url(base: URL(string: "http://localhost:8790")!)!
        XCTAssertTrue(url.absoluteString.contains("org_id="))
    }

    func testDeviceConfigurationStoreSaveLoadAndReset() {
        let suite = "DockWalkTests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suite) else {
            XCTFail("Could not create test defaults suite")
            return
        }
        defer { defaults.removePersistentDomain(forName: suite) }

        DeviceConfigurationStore.clear(using: defaults)
        XCTAssertEqual(DeviceConfigurationStore.load(using: defaults), DeviceConfiguration.devDefaults)

        let custom = DeviceConfiguration(
            apiBaseURLString: "http://192.168.1.50:8790",
            orgId: "org-custom",
            facilityId: "fac-custom",
            facilityName: "Test DC"
        )
        DeviceConfigurationStore.save(custom, using: defaults)
        XCTAssertEqual(DeviceConfigurationStore.load(using: defaults), custom)

        let reset = DeviceConfigurationStore.resetToDevDefaults(using: defaults)
        XCTAssertEqual(reset, DeviceConfiguration.devDefaults)
    }

    func testAppEnvironmentApplyAndReset() {
        let suite = "DockWalkTests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suite) else {
            XCTFail("Could not create test defaults suite")
            return
        }
        defer { defaults.removePersistentDomain(forName: suite) }

        DeviceConfigurationStore.clear(using: defaults)
        let env = AppEnvironment(defaults: defaults)
        let revision = env.configRevision

        XCTAssertNil(
            env.apply(
                apiBaseURLString: "http://10.0.0.5:8790",
                orgId: "org-qa",
                facilityId: "fac-qa"
            )
        )
        XCTAssertEqual(env.apiBaseURL.absoluteString, "http://10.0.0.5:8790")
        XCTAssertEqual(env.orgId, "org-qa")
        XCTAssertGreaterThan(env.configRevision, revision)

        env.resetToDevDefaults()
        XCTAssertEqual(env.orgId, DeviceConfiguration.devDefaults.orgId)
    }
}
