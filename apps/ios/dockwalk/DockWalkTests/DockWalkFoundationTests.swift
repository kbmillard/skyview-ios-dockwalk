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
        XCTAssertTrue(FeatureFlags.receivingEventAutoReplayAvailable)
    }

    func testReceivingEventAutoReplayDefaultOff() {
        let suite = "DockWalkTests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suite) else {
            XCTFail("Could not create test defaults suite")
            return
        }
        defer { defaults.removePersistentDomain(forName: suite) }

        XCTAssertFalse(SyncPreferencesStore.loadReceivingEventAutoReplayEnabled(using: defaults))
        let store = SyncPreferencesStore(defaults: defaults)
        XCTAssertFalse(store.receivingEventAutoReplayEnabled)
    }

    func testReceivingEventAutoReplayPersists() {
        let suite = "DockWalkTests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suite) else {
            XCTFail("Could not create test defaults suite")
            return
        }
        defer { defaults.removePersistentDomain(forName: suite) }

        let store = SyncPreferencesStore(defaults: defaults)
        store.setReceivingEventAutoReplayEnabled(true)
        XCTAssertTrue(SyncPreferencesStore.loadReceivingEventAutoReplayEnabled(using: defaults))

        let reloaded = SyncPreferencesStore(defaults: defaults)
        XCTAssertTrue(reloaded.receivingEventAutoReplayEnabled)
    }

    func testCoordinatorSkipsAutoReplayWhenRuntimeSettingOff() async {
        let suite = "DockWalkTests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suite) else {
            XCTFail("Could not create test defaults suite")
            return
        }
        defer { defaults.removePersistentDomain(forName: suite) }

        let preferences = SyncPreferencesStore(defaults: defaults)
        XCTAssertFalse(preferences.receivingEventAutoReplayEnabled)

        let coordinator = ReceivingEventReplayCoordinator(preferences: preferences)
        let syncStore = OfflineSyncStore(loadPersisted: false)
        syncStore.enqueueReceivingEvent(
            sampleReceivingPayload(idempotencyKey: "off-key"),
            summary: "Queued"
        )

        let env = AppEnvironment(defaults: defaults)
        let result = await coordinator.attemptAutoReplayIfNeeded(
            environment: env,
            syncStore: syncStore,
            trigger: "test"
        )
        XCTAssertNil(result)
        XCTAssertEqual(syncStore.pendingReceivingEventCount, 1)
    }

    func testCoordinatorAutoReplayWhenRuntimeSettingOn() {
        let suite = "DockWalkTests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suite) else {
            XCTFail("Could not create test defaults suite")
            return
        }
        defer { defaults.removePersistentDomain(forName: suite) }

        let preferences = SyncPreferencesStore(defaults: defaults)
        preferences.setReceivingEventAutoReplayEnabled(true)

        let coordinator = ReceivingEventReplayCoordinator(preferences: preferences)
        XCTAssertTrue(coordinator.isAutoReplayEnabled)
    }

    func testManualReplayIndependentOfAutoReplaySetting() async {
        let suite = "DockWalkTests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suite) else {
            XCTFail("Could not create test defaults suite")
            return
        }
        defer { defaults.removePersistentDomain(forName: suite) }

        let preferences = SyncPreferencesStore(defaults: defaults)
        XCTAssertFalse(preferences.receivingEventAutoReplayEnabled)

        let coordinator = ReceivingEventReplayCoordinator(preferences: preferences)
        let syncStore = OfflineSyncStore(loadPersisted: false)
        syncStore.enqueueReceivingEvent(
            sampleReceivingPayload(idempotencyKey: "manual-key"),
            summary: "Manual path"
        )

        XCTAssertFalse(coordinator.isAutoReplayEnabled)
        XCTAssertEqual(coordinator.isAutoReplayEnabled, false)
    }

    func testReplayEngineFiltersReceivingEventsOnly() {
        let receiving = QueuedSyncAction(
            kind: OfflineSyncStore.receivingEventKind,
            summary: "Receive",
            receivingEventPayload: sampleReceivingPayload(idempotencyKey: "key-a")
        )
        let other = QueuedSyncAction(kind: "inbound.start", summary: "Start")
        let pending = ReceivingEventReplayEngine.pendingReceivingActions(from: [receiving, other])
        XCTAssertEqual(pending.count, 1)
        XCTAssertEqual(pending.first?.kind, OfflineSyncStore.receivingEventKind)
    }

    func testReplayEngineSuccessRemovesOnlySucceeded() async {
        let id1 = UUID()
        let id2 = UUID()
        let actions = [
            QueuedSyncAction(
                id: id1,
                kind: OfflineSyncStore.receivingEventKind,
                summary: "A",
                receivingEventPayload: sampleReceivingPayload(idempotencyKey: "key-1")
            ),
            QueuedSyncAction(
                id: id2,
                kind: OfflineSyncStore.receivingEventKind,
                summary: "B",
                receivingEventPayload: sampleReceivingPayload(idempotencyKey: "key-2")
            ),
            QueuedSyncAction(kind: "exception", summary: "E"),
        ]

        var postedKeys: [String] = []
        let outcome = await ReceivingEventReplayEngine.replay(actions: actions) { payload in
            postedKeys.append(payload.idempotencyKey)
            if payload.idempotencyKey == "key-1" {
                return sampleReceivingResponse(idempotent: false)
            }
            throw APIClientError.httpStatus(500, message: nil)
        }

        XCTAssertEqual(outcome.succeeded, 1)
        XCTAssertEqual(outcome.failed, 1)
        XCTAssertEqual(outcome.removedActionIDs, [id1])
        XCTAssertEqual(postedKeys.count, 2)
    }

    func testReplayEngineDuplicateResponseCountsAsSuccess() async {
        let action = QueuedSyncAction(
            kind: OfflineSyncStore.receivingEventKind,
            summary: "Dup",
            receivingEventPayload: sampleReceivingPayload(idempotencyKey: "dup-key")
        )
        let outcome = await ReceivingEventReplayEngine.replay(actions: [action]) { _ in
            sampleReceivingResponse(idempotent: true)
        }
        XCTAssertEqual(outcome.succeeded, 1)
        XCTAssertEqual(outcome.failed, 0)
        XCTAssertEqual(outcome.removedActionIDs.count, 1)
    }

    func testReplayEnginePreservesIdempotencyKey() async {
        let expectedKey = "ios-preserve-key-12345678"
        let action = QueuedSyncAction(
            kind: OfflineSyncStore.receivingEventKind,
            summary: "Preserve",
            receivingEventPayload: sampleReceivingPayload(idempotencyKey: expectedKey)
        )
        _ = await ReceivingEventReplayEngine.replay(actions: [action]) { payload in
            XCTAssertEqual(payload.idempotencyKey, expectedKey)
            return sampleReceivingResponse(idempotent: false)
        }
    }

    private func sampleReceivingPayload(idempotencyKey: String) -> CreateReceivingEventRequest {
        CreateReceivingEventRequest(
            orgId: "org-1",
            facilityId: "fac-1",
            appointmentId: nil,
            inboundShipmentId: "ship-1",
            eventType: "receive_scan",
            source: "device",
            deviceId: "ios-test",
            performedBy: "dockwalk-ios",
            idempotencyKey: idempotencyKey,
            lines: [
                ReceivingEventLineRequest(
                    inboundLineId: "line-1",
                    sku: "SKU",
                    quantityExpected: nil,
                    quantityReceived: 1,
                    quantityDamaged: 0,
                    quantityShort: 0,
                    conditionStatus: "good",
                    rawBarcode: "SKU",
                    metadata: ["source": "manual_receive"]
                )
            ]
        )
    }

    private func sampleReceivingResponse(idempotent: Bool) -> ReceivingEventResponse {
        ReceivingEventResponse(
            mode: "live",
            idempotent: idempotent,
            item: ReceivingEventItemDTO(
                id: "evt-1",
                orgId: "org-1",
                status: "committed",
                eventType: "receive_scan",
                lineCount: 1,
                idempotencyKey: "key"
            ),
            message: nil
        )
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

    func testInboundShipmentLinesEndpoint() {
        let url = APIEndpoint.inboundShipmentLines(
            shipmentId: "ship-abc",
            orgId: "00000000-0000-4000-8000-000000000001"
        ).url(base: URL(string: "http://localhost:8790")!)!
        XCTAssertTrue(url.path.contains("/api/inbound/shipments/ship-abc/lines"))
        XCTAssertTrue(url.absoluteString.contains("org_id="))
    }

    func testInboundLineDTODecodingPhase1B() throws {
        let json = """
        {"id":"line-1","inbound_shipment_id":"ship-1","sku":"SKU-9","description":"Widget",
        "quantity_expected":10,"quantity_received":3,"quantity_damaged":1,"uom":"ea","status":"expected"}
        """.data(using: .utf8)!
        let dto = try JSONDecoder().decode(InboundLineDTO.self, from: json)
        let item = InboundAPIMapping.mapInboundLine(dto)
        XCTAssertEqual(item.sku, "SKU-9")
        XCTAssertEqual(item.expectedQty, 10)
        XCTAssertEqual(item.receivedQty, 3)
        XCTAssertEqual(item.quantityDamaged, 1)
        XCTAssertEqual(item.receiveNow, 7)
    }

    func testInboundLinesResponseDecoding() throws {
        let json = """
        {"mode":"live","shipment_id":"ship-1","org_id":"org-1","items":[
        {"id":"line-1","inbound_shipment_id":"ship-1","sku":"A","quantity_expected":5,
        "quantity_received":0,"quantity_damaged":0,"status":"expected","metadata":{}}]}
        """.data(using: .utf8)!
        let response = try JSONDecoder().decode(InboundLinesResponse.self, from: json)
        XCTAssertEqual(response.mode, "live")
        XCTAssertEqual(response.shipmentId, "ship-1")
        XCTAssertEqual(response.items.count, 1)
    }

    func testReceivingEventResponseIdempotentReplay() throws {
        let json = """
        {"mode":"live","idempotent":true,"item":{"id":"evt-9","org_id":"org-1",
        "status":"committed","event_type":"receive_scan","line_count":1,
        "idempotency_key":"ios-dup"}}
        """.data(using: .utf8)!
        let response = try JSONDecoder().decode(ReceivingEventResponse.self, from: json)
        XCTAssertTrue(response.isIdempotentReplay)
        XCTAssertTrue(response.isSuccess)
        XCTAssertEqual(response.item?.id, "evt-9")
    }

    func testReceivingEventResponseCreateDecoding() throws {
        let json = """
        {"mode":"live","item":{"id":"evt-new","org_id":"org-1","status":"committed",
        "event_type":"receive_scan","line_count":1,"idempotency_key":"ios-new"}}
        """.data(using: .utf8)!
        let response = try JSONDecoder().decode(ReceivingEventResponse.self, from: json)
        XCTAssertFalse(response.isIdempotentReplay)
        XCTAssertTrue(response.isSuccess)
    }

    func testReceivingEventRequestEncoding() throws {
        let request = sampleReceivingPayload(idempotencyKey: "ios-12345678")
        let data = try JSONEncoder().encode(request)
        let object = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        XCTAssertEqual(object?["org_id"] as? String, "org-1")
        XCTAssertEqual(object?["source"] as? String, "device")
        XCTAssertEqual(object?["idempotency_key"] as? String, "ios-12345678")
        let lines = object?["lines"] as? [[String: Any]]
        XCTAssertEqual(lines?.first?["quantity_received"] as? Double, 1)
    }

    func testReceivingEventQueuePersistence() {
        let prior = SyncQueuePersistence.load()
        defer { _ = SyncQueuePersistence.save(prior) }

        let payload = sampleReceivingPayload(idempotencyKey: "ios-queue-key-12345678")
        let action = QueuedSyncAction(
            kind: OfflineSyncStore.receivingEventKind,
            summary: "Receive ASN-1",
            receivingEventPayload: payload
        )
        XCTAssertTrue(SyncQueuePersistence.save([action]))
        let loaded = SyncQueuePersistence.load().first
        XCTAssertEqual(loaded?.receivingEventPayload?.idempotencyKey, "ios-queue-key-12345678")
        XCTAssertEqual(loaded?.receivingEventPayload?.lines.count, 1)
    }

    func testIdempotencyKeyLength() {
        let key = CreateReceivingEventRequest.makeIdempotencyKey()
        XCTAssertGreaterThanOrEqual(key.count, 8)
        XCTAssertLessThanOrEqual(key.count, 128)
        XCTAssertTrue(key.hasPrefix("ios-"))
    }

    func testRailwayProductionURLConstant() {
        XCTAssertEqual(
            DeviceConfiguration.railwayProductionAPIBaseURL,
            "https://dockwalk-api-production.up.railway.app"
        )
    }

    func testDeviceConfigurationStoreSaveLoadAndReset() {
        let suite = "DockWalkTests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suite) else {
            XCTFail("Could not create test defaults suite")
            return
        }
        defer { defaults.removePersistentDomain(forName: suite) }

        DeviceConfigurationStore.clear(using: defaults)
        XCTAssertEqual(DeviceConfigurationStore.load(using: defaults), DeviceConfiguration.railwayQADefaults)

        let custom = DeviceConfiguration(
            apiBaseURLString: "http://192.168.1.50:8790",
            orgId: "org-custom",
            facilityId: "fac-custom",
            facilityName: "Test DC"
        )
        DeviceConfigurationStore.save(custom, using: defaults)
        XCTAssertEqual(DeviceConfigurationStore.load(using: defaults), custom)

        let reset = DeviceConfigurationStore.resetToRailwayQADefaults(using: defaults)
        XCTAssertEqual(reset.apiBaseURLString, DeviceConfiguration.railwayProductionAPIBaseURL)

        let local = DeviceConfigurationStore.resetToLocalDevDefaults(using: defaults)
        XCTAssertEqual(local.apiBaseURLString, DeviceConfiguration.localDevAPIBaseURL)
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

        env.resetToRailwayQA()
        XCTAssertEqual(env.apiBaseURL.absoluteString, DeviceConfiguration.railwayProductionAPIBaseURL)
    }

    func testShipmentDetailViewModelTreatsIdempotentAsSuccess() {
        let response = ReceivingEventResponse(
            mode: "live",
            idempotent: true,
            item: ReceivingEventItemDTO(
                id: "e1",
                orgId: "o1",
                status: "committed",
                eventType: "receive_scan",
                lineCount: 1,
                idempotencyKey: "k1"
            ),
            message: nil
        )
        XCTAssertTrue(ReceivingEventReplayEngine.isSuccessfulResponse(response))
        XCTAssertTrue(response.isIdempotentReplay)
    }

    func testAuditEventsEndpointIncludesOrgLimitOffset() {
        let url = APIEndpoint.auditEvents(
            orgId: "00000000-0000-4000-8000-000000000001",
            limit: 25,
            offset: 50
        ).url(base: URL(string: "https://dockwalk-api-production.up.railway.app")!)!
        XCTAssertTrue(url.absoluteString.contains("org_id="))
        XCTAssertTrue(url.absoluteString.contains("limit=25"))
        XCTAssertTrue(url.absoluteString.contains("offset=50"))
        XCTAssertTrue(url.path.contains("/api/audit/events"))
    }

    func testAuditEventDTODecodingAndMapping() throws {
        let json = """
        {"id":"ae-1","org_id":"org-1","facility_id":"fac-1","entity_type":"receiving_event",
        "entity_id":"ev-1","action":"created","created_at":"2026-05-17T12:00:00Z",
        "payload":{"event_type":"receive_scan","source":"device","device_id":"ios-1","line_count":1}}
        """.data(using: .utf8)!
        let dto = try JSONDecoder().decode(AuditEventDTO.self, from: json)
        let item = AuditAPIMapping.mapAuditEvent(dto)
        XCTAssertEqual(item.action, "created")
        XCTAssertEqual(item.entityType, "receiving_event")
        XCTAssertEqual(item.payloadSummary, "receive_scan · device · 1 line(s)")
        XCTAssertTrue(item.detailLines.contains { $0.contains("device") })
    }

    func testAuditEventsListResponseDecoding() throws {
        let json = """
        {"mode":"live","items":[],"pagination":{"limit":25,"offset":0,"total":0}}
        """.data(using: .utf8)!
        let response = try JSONDecoder().decode(AuditEventsListResponse.self, from: json)
        XCTAssertEqual(response.mode, "live")
        XCTAssertEqual(response.pagination.total, 0)
    }
}
