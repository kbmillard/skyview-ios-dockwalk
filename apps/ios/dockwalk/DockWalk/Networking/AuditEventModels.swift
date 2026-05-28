import Foundation

struct AuditEventDTO: Decodable {
    let id: String
    let orgId: String?
    let facilityId: String?
    let actorUserId: String?
    let entityType: String
    let entityId: String?
    let action: String
    let payload: AuditEventPayloadDTO?
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case orgId = "org_id"
        case facilityId = "facility_id"
        case actorUserId = "actor_user_id"
        case entityType = "entity_type"
        case entityId = "entity_id"
        case action
        case payload
        case createdAt = "created_at"
    }
}

struct AuditEventPayloadDTO: Decodable, Equatable {
    let eventType: String?
    let idempotencyKey: String?
    let source: String?
    let deviceId: String?
    let lineCount: Int?
    let requestId: String?
    let rawBarcode: String?
    let sku: String?
    let upc: String?

    enum CodingKeys: String, CodingKey {
        case eventType = "event_type"
        case idempotencyKey = "idempotency_key"
        case source
        case deviceId = "device_id"
        case lineCount = "line_count"
        case requestId = "request_id"
        case rawBarcode = "raw_barcode"
        case sku
        case upc
    }
}

struct APIPaginationDTO: Decodable, Equatable {
    let limit: Int
    let offset: Int
    let total: Int
}

struct AuditEventsListResponse: Decodable {
    let mode: String
    let message: String?
    let items: [AuditEventDTO]
    let pagination: APIPaginationDTO
}

struct AuditEventItem: Identifiable, Equatable {
    let id: String
    let action: String
    let entityType: String
    let entityId: String?
    let createdAt: Date?
    let facilityId: String?
    let actorUserId: String?
    let payloadSummary: String?
    let detailLines: [String]
    /// UPC / raw barcode / SKU — best display identifier for floor workers.
    let primaryIdentifier: String?
    let payloadSKU: String?
    let payloadEventType: String?
}

enum AuditAPIMapping {
    private static let isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static let isoFormatterNoFraction: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    static func mapAuditEvent(_ dto: AuditEventDTO) -> AuditEventItem {
        let payload = dto.payload
        var detailLines: [String] = []

        if let eventType = payload?.eventType {
            detailLines.append("Event type: \(eventType)")
        }
        if let source = payload?.source {
            detailLines.append("Source: \(source)")
        }
        if let deviceId = payload?.deviceId, !deviceId.isEmpty {
            detailLines.append("Device: \(deviceId)")
        }
        if let key = payload?.idempotencyKey {
            detailLines.append("Idempotency: \(key)")
        }
        if let count = payload?.lineCount {
            detailLines.append("Lines: \(count)")
        }
        if let requestId = payload?.requestId {
            detailLines.append("Request ID: \(requestId)")
        }
        if let facilityId = dto.facilityId {
            detailLines.append("Facility: \(facilityId)")
        }
        if let actor = dto.actorUserId {
            detailLines.append("Actor: \(actor)")
        }

        let summary = payloadSummary(action: dto.action, entityType: dto.entityType, payload: payload)
        let primary = primaryIdentifier(from: payload)

        return AuditEventItem(
            id: dto.id,
            action: dto.action,
            entityType: dto.entityType,
            entityId: dto.entityId,
            createdAt: parseDate(dto.createdAt),
            facilityId: dto.facilityId,
            actorUserId: dto.actorUserId,
            payloadSummary: summary,
            detailLines: detailLines,
            primaryIdentifier: primary,
            payloadSKU: payload?.sku,
            payloadEventType: payload?.eventType
        )
    }

    private static func primaryIdentifier(from payload: AuditEventPayloadDTO?) -> String? {
        guard let payload else { return nil }
        for candidate in [payload.upc, payload.rawBarcode, payload.sku] {
            let trimmed = candidate?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if !trimmed.isEmpty { return trimmed }
        }
        return nil
    }

    private static func payloadSummary(
        action: String,
        entityType: String,
        payload: AuditEventPayloadDTO?
    ) -> String? {
        guard let payload else { return nil }
        var parts: [String] = []
        if let eventType = payload.eventType {
            parts.append(eventType)
        }
        if let source = payload.source {
            parts.append(source)
        }
        if let count = payload.lineCount {
            parts.append("\(count) line(s)")
        }
        guard !parts.isEmpty else { return nil }
        return parts.joined(separator: " · ")
    }

    private static func parseDate(_ raw: String?) -> Date? {
        guard let raw, !raw.isEmpty else { return nil }
        return isoFormatter.date(from: raw) ?? isoFormatterNoFraction.date(from: raw)
    }
}
