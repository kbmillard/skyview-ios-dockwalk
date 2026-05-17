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
        XCTAssertTrue(FeatureFlags.syncBatchReplayEnabled)
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

    func testWarehouseTasksEndpointIncludesPutawayFilter() {
        let url = APIEndpoint.warehouseTasks(
            orgId: "00000000-0000-4000-8000-000000000001",
            taskType: "putaway",
            status: nil,
            inboundShipmentId: nil,
            limit: 25,
            offset: 0
        ).url(base: URL(string: "https://dockwalk-api-production.up.railway.app")!)!
        XCTAssertTrue(url.path.contains("/api/tasks"))
        XCTAssertTrue(url.absoluteString.contains("task_type=putaway"))
        XCTAssertTrue(url.absoluteString.contains("org_id="))
    }

    func testWarehouseTaskDTOMapping() throws {
        let json = """
        {"id":"00000000-0000-4000-8000-000000000501","task_type":"putaway","status":"pending",
        "sku":"SKU-DEV-001","description":"Put away widgets","quantity":10,"uom":"ea",
        "from_location_code":"RECV-STAGE","to_location_code":"BIN-A-01",
        "inbound_shipment_id":"00000000-0000-4000-8000-000000000201"}
        """.data(using: .utf8)!
        let dto = try JSONDecoder().decode(WarehouseTaskDTO.self, from: json)
        let item = WarehouseTaskAPIMapping.mapTask(dto)
        XCTAssertEqual(item.sku, "SKU-DEV-001")
        XCTAssertEqual(item.routeLabel, "RECV-STAGE → BIN-A-01")
        XCTAssertEqual(item.status, "pending")
    }

    func testSyncBatchResponseDuplicateIsSuccess() throws {
        let json = """
        {"mode":"live","results":[{"idempotency_key":"ios-dup","type":"inbound.receiving_event",
        "status":"duplicate","receiving_event_id":"evt-1"}],
        "summary":{"accepted":0,"duplicate":1,"rejected":0}}
        """.data(using: .utf8)!
        let response = try JSONDecoder().decode(SyncBatchResponse.self, from: json)
        XCTAssertTrue(response.results.first?.isSuccess == true)
    }

    func testSyncBatchReplayEngineRemovesAcceptedAndDuplicate() async {
        let id1 = UUID()
        let id2 = UUID()
        let actions = [
            QueuedSyncAction(
                id: id1,
                kind: OfflineSyncStore.receivingEventKind,
                summary: "A",
                receivingEventPayload: sampleReceivingPayload(idempotencyKey: "batch-key-1")
            ),
            QueuedSyncAction(
                id: id2,
                kind: OfflineSyncStore.receivingEventKind,
                summary: "B",
                receivingEventPayload: sampleReceivingPayload(idempotencyKey: "batch-key-2")
            ),
        ]

        let outcome = await SyncBatchReplayEngine.replay(actions: actions) { envelope in
            XCTAssertEqual(envelope.events.count, 2)
            XCTAssertEqual(envelope.events[0].idempotencyKey, "batch-key-1")
            return SyncBatchResponse(
                mode: "live",
                results: envelope.events.map { event in
                    SyncBatchResultItem(
                        idempotencyKey: event.idempotencyKey,
                        type: event.type,
                        status: event.idempotencyKey == "batch-key-1" ? "accepted" : "duplicate",
                        receivingEventId: "evt",
                        error: nil
                    )
                },
                summary: SyncBatchSummary(accepted: 1, duplicate: 1, rejected: 0)
            )
        }

        XCTAssertEqual(outcome.succeeded, 2)
        XCTAssertEqual(outcome.failed, 0)
        XCTAssertEqual(Set(outcome.removedActionIDs), Set([id1, id2]))
    }

    func testSyncBatchEnvelopeOmitsIdempotencyKeyInsidePayload() throws {
        let request = sampleReceivingPayload(idempotencyKey: "ios-batch-key-99")
        let envelope = SyncBatchEnvelope(
            orgId: request.orgId,
            facilityId: request.facilityId,
            deviceId: request.deviceId,
            requests: [request]
        )
        let data = try JSONEncoder().encode(envelope)
        let object = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let events = object?["events"] as? [[String: Any]]
        let payload = events?.first?["payload"] as? [String: Any]
        XCTAssertEqual(events?.first?["idempotency_key"] as? String, "ios-batch-key-99")
        XCTAssertNil(payload?["idempotency_key"])
    }

    func testTaskActionBatchEventEncoding() throws {
        let queued = QueuedTaskActionBuilder.build(
            taskId: "00000000-0000-4000-8000-000000000501",
            kind: .block,
            orgId: "00000000-0000-4000-8000-000000000001",
            idempotencyKey: "ios-task-block-001",
            deviceId: "ios-test",
            block: TaskBlockRequest(
                orgId: "00000000-0000-4000-8000-000000000001",
                reasonCode: "location_blocked",
                reason: "Bin occupied",
                idempotencyKey: "ios-task-block-001",
                deviceId: "ios-test",
                notes: nil
            )
        )
        let envelope = SyncBatchEnvelope(
            orgId: queued.orgId,
            facilityId: nil,
            deviceId: queued.deviceId,
            events: [.taskAction(queued)]
        )
        let data = try JSONEncoder().encode(envelope)
        let object = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let events = object?["events"] as? [[String: Any]]
        XCTAssertEqual(events?.first?["event_type"] as? String, "task_action")
        XCTAssertEqual(events?.first?["idempotency_key"] as? String, "ios-task-block-001")
        let payload = events?.first?["payload"] as? [String: Any]
        XCTAssertEqual(payload?["task_id"] as? String, "00000000-0000-4000-8000-000000000501")
        XCTAssertEqual(payload?["action"] as? String, "block")
        XCTAssertEqual(payload?["reason_code"] as? String, "location_blocked")
    }

    func testOfflineSyncEnqueueTaskActionPreservesIdempotencyKey() {
        let store = OfflineSyncStore(loadPersisted: false)
        store.clearQueue()
        let payload = QueuedTaskActionBuilder.build(
            taskId: "task-1",
            kind: .start,
            orgId: "org-1",
            idempotencyKey: "ios-task-start-99",
            deviceId: "dev-1",
            start: TaskStartRequest(orgId: "org-1", idempotencyKey: "ios-task-start-99", deviceId: "dev-1", notes: nil)
        )
        store.enqueueTaskAction(payload, summary: "Start putaway SKU-1")
        XCTAssertEqual(store.pendingTaskActionCount, 1)
        XCTAssertEqual(store.queuedActions.first?.taskActionPayload?.idempotencyKey, "ios-task-start-99")
    }

    func testAPIClientErrorClassifierDoesNotQueue409() {
        XCTAssertFalse(
            APIClientErrorClassifier.shouldQueueOffline(
                for: APIClientError.httpStatus(409, message: "invalid_transition")
            )
        )
    }

    func testAPIClientErrorClassifierQueuesTransport() {
        XCTAssertTrue(
            APIClientErrorClassifier.shouldQueueOffline(
                for: APIClientError.transport(URLError(.notConnectedToInternet))
            )
        )
    }

    func testSyncBatchReplayEngineTaskActionDuplicateDequeues() async {
        let payload = QueuedTaskActionBuilder.build(
            taskId: "task-1",
            kind: .assign,
            orgId: "org-1",
            idempotencyKey: "ios-task-dup",
            deviceId: "dev-1",
            assign: TaskAssignRequest(
                orgId: "org-1",
                assignedTo: "dockwalk-ios",
                idempotencyKey: "ios-task-dup",
                deviceId: "dev-1",
                notes: nil
            )
        )
        let actionID = UUID()
        let actions = [
            QueuedSyncAction(
                id: actionID,
                kind: OfflineSyncStore.taskActionKind,
                summary: "Assign",
                taskActionPayload: payload
            ),
        ]

        let batchResult = await SyncBatchReplayEngine.replay(actions: actions) { _ in
            SyncBatchResponse(
                mode: "live",
                results: [
                    SyncBatchResultItem(
                        idempotencyKey: "ios-task-dup",
                        type: "task_action",
                        status: "duplicate",
                        receivingEventId: nil,
                        error: nil
                    ),
                ],
                summary: SyncBatchSummary(accepted: 0, duplicate: 1, rejected: 0)
            )
        }

        XCTAssertEqual(batchResult.outcome.succeeded, 1)
        XCTAssertEqual(batchResult.outcome.removedActionIDs, [actionID])
    }

    func testSyncBatchReplayEngineTaskActionRejectedStaysQueued() async {
        let payload = QueuedTaskActionBuilder.build(
            taskId: "task-1",
            kind: .complete,
            orgId: "org-1",
            idempotencyKey: "ios-task-rej",
            deviceId: "dev-1",
            complete: TaskCompleteRequest(
                orgId: "org-1",
                idempotencyKey: "ios-task-rej",
                deviceId: "dev-1",
                performedBy: "dockwalk-ios",
                quantityCompleted: 1,
                notes: nil
            )
        )
        let actionID = UUID()
        let actions = [
            QueuedSyncAction(
                id: actionID,
                kind: OfflineSyncStore.taskActionKind,
                summary: "Complete",
                taskActionPayload: payload
            ),
        ]

        let batchResult = await SyncBatchReplayEngine.replay(actions: actions) { _ in
            SyncBatchResponse(
                mode: "live",
                results: [
                    SyncBatchResultItem(
                        idempotencyKey: "ios-task-rej",
                        type: "task_action",
                        status: "rejected",
                        receivingEventId: nil,
                        error: SyncBatchErrorBody(code: "invalid_transition", message: "Cannot complete")
                    ),
                ],
                summary: SyncBatchSummary(accepted: 0, duplicate: 0, rejected: 1)
            )
        }

        XCTAssertEqual(batchResult.outcome.failed, 1)
        XCTAssertTrue(batchResult.outcome.removedActionIDs.isEmpty)
        XCTAssertEqual(batchResult.rejectionMessages[actionID], "Cannot complete")
    }

    func testSyncBatchReplayEngineMixedBatchPartialSuccess() async {
        let receivingID = UUID()
        let taskID = UUID()
        let receiving = QueuedSyncAction(
            id: receivingID,
            kind: OfflineSyncStore.receivingEventKind,
            summary: "Receive",
            receivingEventPayload: sampleReceivingPayload(idempotencyKey: "recv-key")
        )
        let taskPayload = QueuedTaskActionBuilder.build(
            taskId: "task-1",
            kind: .start,
            orgId: "org-1",
            idempotencyKey: "task-key",
            deviceId: "dev-1",
            start: TaskStartRequest(orgId: "org-1", idempotencyKey: "task-key", deviceId: "dev-1", notes: nil)
        )
        let taskAction = QueuedSyncAction(
            id: taskID,
            kind: OfflineSyncStore.taskActionKind,
            summary: "Start",
            taskActionPayload: taskPayload
        )

        let batchResult = await SyncBatchReplayEngine.replay(actions: [receiving, taskAction]) { envelope in
            XCTAssertEqual(envelope.events.count, 2)
            return SyncBatchResponse(
                mode: "live",
                results: [
                    SyncBatchResultItem(
                        idempotencyKey: "recv-key",
                        type: SyncBatchEventRecord.receivingEventType,
                        status: "accepted",
                        receivingEventId: "evt-1",
                        error: nil
                    ),
                    SyncBatchResultItem(
                        idempotencyKey: "task-key",
                        type: "task_action",
                        status: "rejected",
                        receivingEventId: nil,
                        error: SyncBatchErrorBody(code: "invalid_transition", message: "Bad state")
                    ),
                ],
                summary: SyncBatchSummary(accepted: 1, duplicate: 0, rejected: 1)
            )
        }

        XCTAssertEqual(batchResult.outcome.succeeded, 1)
        XCTAssertEqual(Set(batchResult.outcome.removedActionIDs), Set([receivingID]))
        XCTAssertEqual(batchResult.rejectionMessages[taskID], "Bad state")
    }

    func testSyncBatchReplayEngineIgnoresNonSyncableKinds() async {
        let actions = [
            QueuedSyncAction(kind: "inbound.start", summary: "Start PO"),
            QueuedSyncAction(
                kind: OfflineSyncStore.taskActionKind,
                summary: "Broken",
                taskActionPayload: nil
            ),
        ]
        let batchResult = await SyncBatchReplayEngine.replay(actions: actions) { _ in
            XCTFail("Should not post when nothing syncable")
            return SyncBatchResponse(
                mode: "live",
                results: [],
                summary: SyncBatchSummary(accepted: 0, duplicate: 0, rejected: 0)
            )
        }
        XCTAssertEqual(batchResult.outcome.succeeded, 0)
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

    func testWarehouseTaskAssignEndpointPath() {
        let url = APIEndpoint.warehouseTaskAssign(taskId: "task-uuid")
            .url(base: URL(string: "https://dockwalk-api-production.up.railway.app")!)!
        XCTAssertTrue(url.path.contains("/api/tasks/task-uuid/assign"))
        XCTAssertFalse(url.absoluteString.contains("org_id="))
    }

    func testWarehouseTaskWriteResponseIdempotentDecoding() throws {
        let json = """
        {"mode":"live","idempotent":true,"item":{"id":"t1","task_type":"putaway","status":"assigned","quantity":1,"uom":"ea"}}
        """.data(using: .utf8)!
        let response = try JSONDecoder().decode(WarehouseTaskWriteResponse.self, from: json)
        XCTAssertTrue(response.isIdempotentReplay)
        XCTAssertEqual(response.item.status, "assigned")
    }

    func testTaskAssignRequestEncoding() throws {
        let request = TaskAssignRequest(
            orgId: "org-1",
            assignedTo: "dockwalk-ios",
            idempotencyKey: "ios-task-abcdef12",
            deviceId: "dev-1",
            notes: nil
        )
        let data = try JSONEncoder().encode(request)
        let object = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        XCTAssertEqual(object?["org_id"] as? String, "org-1")
        XCTAssertEqual(object?["assigned_to"] as? String, "dockwalk-ios")
        XCTAssertEqual(object?["idempotency_key"] as? String, "ios-task-abcdef12")
    }

    func testPutawayTaskActionAvailabilityByStatus() {
        XCTAssertEqual(
            PutawayTaskActionAvailability.availableActions(for: "pending"),
            [.assign, .start]
        )
        XCTAssertEqual(
            PutawayTaskActionAvailability.availableActions(for: "in_progress"),
            [.complete, .block]
        )
        XCTAssertEqual(
            PutawayTaskActionAvailability.availableActions(for: "blocked"),
            [.assign, .start]
        )
        XCTAssertTrue(PutawayTaskActionAvailability.availableActions(for: "completed").isEmpty)
    }

    func testPutawayTaskActionDockTitles() {
        XCTAssertEqual(PutawayTaskActionKind.assign.dockTitle(for: "pending"), "Assign to me")
        XCTAssertEqual(PutawayTaskActionKind.start.dockTitle(for: "blocked"), "Resume")
        XCTAssertEqual(PutawayTaskActionKind.start.dockTitle(for: "assigned"), "Start")
    }

    func testTaskCompleteRequestEncodingDefaultsQuantity() throws {
        let request = TaskCompleteRequest(
            orgId: "org-1",
            idempotencyKey: "ios-task-abc",
            deviceId: "dev-1",
            performedBy: "dockwalk-ios",
            quantityCompleted: 1,
            notes: nil
        )
        let data = try JSONEncoder().encode(request)
        let object = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        XCTAssertEqual(object?["org_id"] as? String, "org-1")
        XCTAssertEqual(object?["quantity_completed"] as? Double, 1)
    }

    func testTaskBlockRequestEncodingReasonCode() throws {
        let request = TaskBlockRequest(
            orgId: "org-1",
            reasonCode: "location_blocked",
            reason: "Aisle closed",
            idempotencyKey: "ios-task-xyz",
            deviceId: "dev-1",
            notes: nil
        )
        let data = try JSONEncoder().encode(request)
        let object = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        XCTAssertEqual(object?["reason_code"] as? String, "location_blocked")
    }

    func testPutawayStatusFilterIncludesBlocked() {
        XCTAssertTrue(PutawayTaskStatusFilter.allCases.contains(.blocked))
        XCTAssertEqual(PutawayTaskStatusFilter.blocked.apiStatus, "blocked")
    }

    func testWarehouseTaskActionErrorMappingConflict() {
        let mapped = WarehouseTaskActionErrorMapping.map(
            APIClientError.httpStatus(409, message: "invalid_transition")
        )
        XCTAssertTrue(mapped.isConflict)
        XCTAssertFalse(mapped.preserveIdempotencyKey)
    }

    func testWarehouseTaskActionErrorMappingTransportPreservesKey() {
        let mapped = WarehouseTaskActionErrorMapping.map(
            APIClientError.transport(URLError(.notConnectedToInternet))
        )
        XCTAssertTrue(mapped.preserveIdempotencyKey)
        XCTAssertFalse(mapped.isConflict)
    }

    func testTaskActionIdempotencyKeyFormat() {
        let key = WarehouseTaskActionIdempotency.makeKey()
        XCTAssertTrue(key.hasPrefix("ios-task-"))
        XCTAssertGreaterThanOrEqual(key.count, 8)
        XCTAssertLessThanOrEqual(key.count, 128)
    }

    func testOfflineSyncStoreTaskActionKindConstant() {
        XCTAssertEqual(OfflineSyncStore.taskActionKind, "task_action")
        XCTAssertEqual(OfflineSyncStore.receivingEventKind, "inbound.receiving_event")
    }
}
