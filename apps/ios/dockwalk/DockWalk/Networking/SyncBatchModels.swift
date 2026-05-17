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

struct SyncBatchEventItem: Encodable, Equatable {
    let type: String
    let idempotencyKey: String
    let payload: SyncReceivingEventPayload

    enum CodingKeys: String, CodingKey {
        case type
        case idempotencyKey = "idempotency_key"
        case payload
    }

    static let receivingEventType = "inbound.receiving_event"

    init(from request: CreateReceivingEventRequest) {
        type = Self.receivingEventType
        idempotencyKey = request.idempotencyKey
        payload = SyncReceivingEventPayload(from: request)
    }
}

struct SyncBatchEnvelope: Encodable, Equatable {
    let orgId: String
    let facilityId: String?
    let deviceId: String?
    let events: [SyncBatchEventItem]

    enum CodingKeys: String, CodingKey {
        case orgId = "org_id"
        case facilityId = "facility_id"
        case deviceId = "device_id"
        case events
    }

    init(orgId: String, facilityId: String?, deviceId: String?, requests: [CreateReceivingEventRequest]) {
        self.orgId = orgId
        self.facilityId = facilityId
        self.deviceId = deviceId ?? requests.first?.deviceId
        self.events = requests.map { SyncBatchEventItem(from: $0) }
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
        case status
        case receivingEventId = "receiving_event_id"
        case error
    }

    var isSuccess: Bool {
        status == "accepted" || status == "duplicate"
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
