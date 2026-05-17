import Foundation

// MARK: - Write requests (POST /api/tasks/:id/*)

struct TaskAssignRequest: Encodable, Equatable {
    let orgId: String
    let assignedTo: String
    let idempotencyKey: String
    var deviceId: String?
    var notes: String?

    enum CodingKeys: String, CodingKey {
        case orgId = "org_id"
        case assignedTo = "assigned_to"
        case idempotencyKey = "idempotency_key"
        case deviceId = "device_id"
        case notes
    }
}

struct TaskStartRequest: Encodable, Equatable {
    let orgId: String
    let idempotencyKey: String
    var deviceId: String?
    var notes: String?

    enum CodingKeys: String, CodingKey {
        case orgId = "org_id"
        case idempotencyKey = "idempotency_key"
        case deviceId = "device_id"
        case notes
    }
}

struct TaskBlockRequest: Encodable, Equatable {
    let orgId: String
    let reasonCode: String
    let reason: String
    let idempotencyKey: String
    var deviceId: String?
    var notes: String?

    enum CodingKeys: String, CodingKey {
        case orgId = "org_id"
        case reasonCode = "reason_code"
        case reason
        case idempotencyKey = "idempotency_key"
        case deviceId = "device_id"
        case notes
    }
}

struct TaskCompleteRequest: Encodable, Equatable {
    let orgId: String
    let idempotencyKey: String
    var deviceId: String?
    var performedBy: String?
    var quantityCompleted: Double?
    var notes: String?

    enum CodingKeys: String, CodingKey {
        case orgId = "org_id"
        case idempotencyKey = "idempotency_key"
        case deviceId = "device_id"
        case performedBy = "performed_by"
        case quantityCompleted = "quantity_completed"
        case notes
    }
}

// MARK: - Write response

struct WarehouseTaskWriteResponse: Decodable, Equatable {
    let mode: String
    let idempotent: Bool?
    let item: WarehouseTaskDTO

    var isIdempotentReplay: Bool { idempotent == true }
}

// MARK: - Actions

enum PutawayTaskActionKind: String, CaseIterable, Identifiable {
    case assign
    case start
    case block
    case complete

    var id: String { rawValue }

    var title: String {
        switch self {
        case .assign: return "Assign"
        case .start: return "Start"
        case .block: return "Block"
        case .complete: return "Complete"
        }
    }

    var systemImage: String {
        switch self {
        case .assign: return "person.badge.plus"
        case .start: return "play.fill"
        case .block: return "hand.raised.fill"
        case .complete: return "checkmark.circle.fill"
        }
    }
}

enum PutawayTaskActionAvailability {
    static func availableActions(for status: String) -> [PutawayTaskActionKind] {
        switch status {
        case "pending":
            return [.assign, .start]
        case "assigned":
            return [.start, .block]
        case "in_progress":
            return [.block, .complete]
        case "blocked":
            return [.assign, .start]
        case "completed", "cancelled":
            return []
        default:
            return []
        }
    }
}

enum WarehouseTaskActionIdempotency {
    static let operatorId = "dockwalk-ios"

    static func makeKey() -> String {
        let suffix = UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased()
        return "ios-task-\(suffix)"
    }
}

enum WarehouseTaskActionErrorMapping {
    struct MappedError {
        let message: String
        let isConflict: Bool
        let preserveIdempotencyKey: Bool
    }

    static func map(_ error: Error) -> MappedError {
        if let apiError = error as? APIClientError {
            switch apiError {
            case .transport:
                return MappedError(
                    message: "Not submitted — check connection and try again.",
                    isConflict: false,
                    preserveIdempotencyKey: true
                )
            case .httpStatus(409, let message):
                return MappedError(
                    message: message ?? "This task was updated elsewhere. Refreshing…",
                    isConflict: true,
                    preserveIdempotencyKey: false
                )
            case .httpStatus(422, let message):
                return MappedError(
                    message: message ?? "Invalid request for this task state.",
                    isConflict: false,
                    preserveIdempotencyKey: false
                )
            case .httpStatus(_, let message):
                return MappedError(
                    message: message ?? apiError.errorDescription ?? "Request failed.",
                    isConflict: false,
                    preserveIdempotencyKey: false
                )
            case .invalidURL, .decoding:
                return MappedError(
                    message: apiError.errorDescription ?? "Request failed.",
                    isConflict: false,
                    preserveIdempotencyKey: false
                )
            }
        }
        return MappedError(
            message: error.localizedDescription,
            isConflict: false,
            preserveIdempotencyKey: true
        )
    }
}
