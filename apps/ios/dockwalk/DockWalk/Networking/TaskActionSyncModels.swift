import Foundation

/// Persisted payload for a queued putaway task action (direct-route body + sync batch shape).
struct QueuedTaskActionPayload: Codable, Equatable {
    let taskId: String
    let action: String
    let orgId: String
    let idempotencyKey: String
    let deviceId: String?
    let createdAt: Date
    var assignedTo: String?
    var reasonCode: String?
    var reason: String?
    var performedBy: String?
    var quantityCompleted: Double?
    var notes: String?

    var actionKind: PutawayTaskActionKind? {
        PutawayTaskActionKind(rawValue: action)
    }

    var isoCreatedAt: String {
        Self.isoFormatter.string(from: createdAt)
    }

    private static let isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    func syncPayloadBody() -> SyncTaskActionPayloadBody {
        SyncTaskActionPayloadBody(
            taskId: taskId,
            action: action,
            assignedTo: assignedTo,
            reasonCode: reasonCode,
            reason: reason,
            performedBy: performedBy,
            quantityCompleted: quantityCompleted,
            notes: notes,
            metadata: [:]
        )
    }

    static func summary(for kind: PutawayTaskActionKind, sku: String) -> String {
        switch kind {
        case .assign: return "Assign putaway \(sku)"
        case .start: return "Start putaway \(sku)"
        case .block: return "Block putaway \(sku)"
        case .complete: return "Complete putaway \(sku)"
        }
    }
}

struct SyncTaskActionPayloadBody: Encodable, Equatable {
    let taskId: String
    let action: String
    var assignedTo: String?
    var reasonCode: String?
    var reason: String?
    var performedBy: String?
    var quantityCompleted: Double?
    var notes: String?
    var metadata: [String: String]

    enum CodingKeys: String, CodingKey {
        case taskId = "task_id"
        case action
        case assignedTo = "assigned_to"
        case reasonCode = "reason_code"
        case reason
        case performedBy = "performed_by"
        case quantityCompleted = "quantity_completed"
        case notes
        case metadata
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(taskId, forKey: .taskId)
        try container.encode(action, forKey: .action)
        if let assignedTo { try container.encode(assignedTo, forKey: .assignedTo) }
        if let reasonCode { try container.encode(reasonCode, forKey: .reasonCode) }
        if let reason { try container.encode(reason, forKey: .reason) }
        if let performedBy { try container.encode(performedBy, forKey: .performedBy) }
        if let quantityCompleted { try container.encode(quantityCompleted, forKey: .quantityCompleted) }
        if let notes { try container.encode(notes, forKey: .notes) }
        if !metadata.isEmpty { try container.encode(metadata, forKey: .metadata) }
    }
}

enum QueuedTaskActionBuilder {
    static func build(
        taskId: String,
        kind: PutawayTaskActionKind,
        orgId: String,
        idempotencyKey: String,
        deviceId: String?,
        assign: TaskAssignRequest? = nil,
        start: TaskStartRequest? = nil,
        block: TaskBlockRequest? = nil,
        complete: TaskCompleteRequest? = nil
    ) -> QueuedTaskActionPayload {
        switch kind {
        case .assign:
            return QueuedTaskActionPayload(
                taskId: taskId,
                action: kind.rawValue,
                orgId: orgId,
                idempotencyKey: idempotencyKey,
                deviceId: deviceId,
                createdAt: .now,
                assignedTo: assign?.assignedTo ?? WarehouseTaskActionIdempotency.operatorId,
                reasonCode: nil,
                reason: nil,
                performedBy: nil,
                quantityCompleted: nil,
                notes: assign?.notes
            )
        case .start:
            return QueuedTaskActionPayload(
                taskId: taskId,
                action: kind.rawValue,
                orgId: orgId,
                idempotencyKey: idempotencyKey,
                deviceId: deviceId,
                createdAt: .now,
                assignedTo: nil,
                reasonCode: nil,
                reason: nil,
                performedBy: nil,
                quantityCompleted: nil,
                notes: start?.notes
            )
        case .block:
            return QueuedTaskActionPayload(
                taskId: taskId,
                action: kind.rawValue,
                orgId: orgId,
                idempotencyKey: idempotencyKey,
                deviceId: deviceId,
                createdAt: .now,
                assignedTo: nil,
                reasonCode: block?.reasonCode,
                reason: block?.reason,
                performedBy: nil,
                quantityCompleted: nil,
                notes: block?.notes
            )
        case .complete:
            return QueuedTaskActionPayload(
                taskId: taskId,
                action: kind.rawValue,
                orgId: orgId,
                idempotencyKey: idempotencyKey,
                deviceId: deviceId,
                createdAt: .now,
                assignedTo: nil,
                reasonCode: nil,
                reason: nil,
                performedBy: complete?.performedBy ?? WarehouseTaskActionIdempotency.operatorId,
                quantityCompleted: complete?.quantityCompleted,
                notes: complete?.notes
            )
        }
    }
}
