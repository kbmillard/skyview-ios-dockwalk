import Foundation

struct QueuedSyncAction: Identifiable, Equatable, Codable {
    let id: UUID
    let kind: String
    let summary: String
    let createdAt: Date
    /// JSON-encoded `CreateReceivingEventRequest` when `kind == inbound.receiving_event`.
    var receivingEventPayload: CreateReceivingEventRequest?
    var appointmentUpdatePayload: AppointmentUpdateRequest?
    var orgId: String?
    /// Persisted putaway task action when `kind == task_action`.
    var taskActionPayload: QueuedTaskActionPayload?
    var finalizePayload: InboundFinalizeRequest?
    var movementPayload: InventoryMovementRequest?
    var outboundTransitionPayload: OutboundOrderTransitionRequest?
    /// Load id for FIFO dependency (movement waits for finalize).
    var inboundLoadId: String?
    var appointmentId: String?
    /// Outbound order id for shipping transition replay.
    var outboundOrderId: String?
    /// Optional dependency chain marker (for staged replays requiring inbound finalize first).
    var dependencyLoadId: String?
    var clientLineId: String?
    /// Last batch replay rejection or transport summary for display.
    var lastError: String?

    init(
        id: UUID = UUID(),
        kind: String,
        summary: String,
        createdAt: Date = .now,
        receivingEventPayload: CreateReceivingEventRequest? = nil,
        appointmentUpdatePayload: AppointmentUpdateRequest? = nil,
        orgId: String? = nil,
        taskActionPayload: QueuedTaskActionPayload? = nil,
        finalizePayload: InboundFinalizeRequest? = nil,
        movementPayload: InventoryMovementRequest? = nil,
        outboundTransitionPayload: OutboundOrderTransitionRequest? = nil,
        inboundLoadId: String? = nil,
        appointmentId: String? = nil,
        outboundOrderId: String? = nil,
        dependencyLoadId: String? = nil,
        clientLineId: String? = nil,
        lastError: String? = nil
    ) {
        self.id = id
        self.kind = kind
        self.summary = summary
        self.createdAt = createdAt
        self.receivingEventPayload = receivingEventPayload
        self.appointmentUpdatePayload = appointmentUpdatePayload
        self.orgId = orgId
        self.taskActionPayload = taskActionPayload
        self.finalizePayload = finalizePayload
        self.movementPayload = movementPayload
        self.outboundTransitionPayload = outboundTransitionPayload
        self.inboundLoadId = inboundLoadId
        self.appointmentId = appointmentId
        self.outboundOrderId = outboundOrderId
        self.dependencyLoadId = dependencyLoadId
        self.clientLineId = clientLineId
        self.lastError = lastError
    }
}

enum SyncQueuePersistence {
    private static let fileName = "dockwalk_sync_queue.json"

    static func fileURL() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let folder = base.appendingPathComponent("DockWalk", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder.appendingPathComponent(fileName)
    }

    static func load() -> [QueuedSyncAction] {
        let url = fileURL()
        guard FileManager.default.fileExists(atPath: url.path) else { return [] }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode([QueuedSyncAction].self, from: data)
        } catch {
            return []
        }
    }

    @discardableResult
    static func save(_ actions: [QueuedSyncAction]) -> Bool {
        do {
            let data = try JSONEncoder().encode(actions)
            try data.write(to: fileURL(), options: .atomic)
            return true
        } catch {
            return false
        }
    }
}
