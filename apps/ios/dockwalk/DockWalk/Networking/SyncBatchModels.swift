import Foundation

struct SyncReceivingEventPayload: Encodable, Equatable {
    var facilityId: String?
    var appointmentId: String?
    var inboundShipmentId: String?
    let eventType: String
    var status: String?
    var source: String?
    var deviceId: String?
    var performedBy: String?
    var notes: String?
    var lines: [ReceivingEventLineRequest]

    enum CodingKeys: String, CodingKey {
        case facilityId = "facility_id"
        case appointmentId = "appointment_id"
        case inboundShipmentId = "inbound_shipment_id"
        case eventType = "event_type"
        case status
        case source
        case deviceId = "device_id"
        case performedBy = "performed_by"
        case notes
        case lines
    }

    init(from request: CreateReceivingEventRequest) {
        facilityId = request.facilityId
        appointmentId = request.appointmentId
        inboundShipmentId = request.inboundShipmentId
        eventType = request.eventType
        status = "committed"
        source = request.source
        deviceId = request.deviceId
        performedBy = request.performedBy
        notes = request.notes
        lines = request.lines
    }
}

/// One row in `POST /api/sync/events` — receiving (`type`) or task_action (`event_type`).
enum SyncBatchEventRecord: Encodable, Equatable {
    case receiving(CreateReceivingEventRequest)
    case taskAction(QueuedTaskActionPayload)

    static let receivingEventType = "inbound.receiving_event"
    static let taskActionEventType = "task_action"

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .receiving(let request):
            try container.encode(Self.receivingEventType, forKey: .type)
            try container.encode(request.idempotencyKey, forKey: .idempotencyKey)
            try container.encode(SyncReceivingEventPayload(from: request), forKey: .payload)
        case .taskAction(let payload):
            try container.encode(Self.taskActionEventType, forKey: .eventType)
            try container.encode(payload.idempotencyKey, forKey: .idempotencyKey)
            try container.encode(payload.isoCreatedAt, forKey: .createdAt)
            try container.encode(payload.syncPayloadBody(), forKey: .payload)
        }
    }

    var idempotencyKey: String {
        switch self {
        case .receiving(let request): return request.idempotencyKey
        case .taskAction(let payload): return payload.idempotencyKey
        }
    }

    var orgId: String {
        switch self {
        case .receiving(let request): return request.orgId
        case .taskAction(let payload): return payload.orgId
        }
    }

    private enum CodingKeys: String, CodingKey {
        case type
        case eventType = "event_type"
        case idempotencyKey = "idempotency_key"
        case createdAt = "created_at"
        case payload
    }
}

struct SyncBatchEnvelope: Encodable, Equatable {
    let orgId: String
    let facilityId: String?
    let deviceId: String?
    let source: String?
    let events: [SyncBatchEventRecord]

    enum CodingKeys: String, CodingKey {
        case orgId = "org_id"
        case facilityId = "facility_id"
        case deviceId = "device_id"
        case source
        case events
    }

    init(orgId: String, facilityId: String?, deviceId: String?, requests: [CreateReceivingEventRequest]) {
        self.orgId = orgId
        self.facilityId = facilityId
        self.deviceId = deviceId ?? requests.first?.deviceId
        self.source = "device"
        self.events = requests.map { .receiving($0) }
    }

    init(orgId: String, facilityId: String?, deviceId: String?, events: [SyncBatchEventRecord]) {
        self.orgId = orgId
        self.facilityId = facilityId
        self.deviceId = deviceId
        self.source = "device"
        self.events = events
    }
}

struct SyncBatchResultItem: Decodable, Equatable {
    let idempotencyKey: String
    let type: String
    let status: String
    let receivingEventId: String?
    let error: SyncBatchErrorBody?

    enum CodingKeys: String, CodingKey {
        case idempotencyKey = "idempotency_key"
        case type
        case eventType = "event_type"
        case status
        case receivingEventId = "receiving_event_id"
        case error
    }

    init(
        idempotencyKey: String,
        type: String,
        status: String,
        receivingEventId: String?,
        error: SyncBatchErrorBody?
    ) {
        self.idempotencyKey = idempotencyKey
        self.type = type
        self.status = status
        self.receivingEventId = receivingEventId
        self.error = error
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        idempotencyKey = try container.decode(String.self, forKey: .idempotencyKey)
        type = try container.decodeIfPresent(String.self, forKey: .type)
            ?? container.decodeIfPresent(String.self, forKey: .eventType)
            ?? ""
        status = try container.decode(String.self, forKey: .status)
        receivingEventId = try container.decodeIfPresent(String.self, forKey: .receivingEventId)
        error = try container.decodeIfPresent(SyncBatchErrorBody.self, forKey: .error)
    }

    var isSuccess: Bool {
        status == "accepted" || status == "duplicate"
    }

    var rejectionMessage: String? {
        guard status == "rejected" else { return nil }
        if let error, !error.message.isEmpty { return error.message }
        return "Rejected by server"
    }
}

struct SyncBatchErrorBody: Decodable, Equatable {
    let code: String
    let message: String
}

struct SyncBatchSummary: Decodable, Equatable {
    let accepted: Int
    let duplicate: Int
    let rejected: Int
}

struct SyncBatchResponse: Decodable, Equatable {
    let mode: String
    let results: [SyncBatchResultItem]
    let summary: SyncBatchSummary
}
