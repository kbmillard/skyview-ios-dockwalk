import Foundation

/// Unified putaway task status matching backend task status contract
/// rawValue matches API slug from backend z.enum(["pending", "assigned", "in_progress", "blocked", "completed", "cancelled"])
enum PutawayTaskStatus: String, CaseIterable, Codable {
    case pending = "pending"
    case assigned = "assigned"
    case inProgress = "in_progress"
    case blocked = "blocked"
    case completed = "completed"
    case cancelled = "cancelled"
    
    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .assigned: return "Assigned"
        case .inProgress: return "In Progress"
        case .blocked: return "Blocked"
        case .completed: return "Completed"
        case .cancelled: return "Cancelled"
        }
    }
    
    var chipTone: StatusChip.Tone {
        switch self {
        case .pending: return .neutral
        case .assigned: return .info
        case .inProgress: return .warning
        case .blocked: return .danger
        case .completed: return .success
        case .cancelled: return .neutral
        }
    }
    
    var systemImage: String {
        switch self {
        case .pending: return "square.stack"
        case .assigned: return "person.crop.circle"
        case .inProgress: return "arrow.triangle.2.circlepath"
        case .blocked: return "exclamationmark.triangle"
        case .completed: return "checkmark.circle"
        case .cancelled: return "xmark.circle"
        }
    }
}

// MARK: - WorkflowStatus Conformance
extension PutawayTaskStatus: WorkflowStatus {
    var id: String { rawValue }
    
    var sortOrder: Int {
        switch self {
        case .pending: return 0
        case .assigned: return 1
        case .inProgress: return 2
        case .blocked: return 3
        case .completed: return 4
        case .cancelled: return 5
        }
    }
}

/// Putaway task item (client model)
struct PutawayTaskItem: Identifiable, Equatable {
    let id: String
    let sku: String
    let description: String
    let quantity: Double
    let uom: String
    let status: PutawayTaskStatus
    let fromLocationCode: String
    let toLocationCode: String
    let inboundShipmentId: String?
    let createdAt: Date?

    var routeLabel: String {
        if fromLocationCode.isEmpty && toLocationCode.isEmpty { return "—" }
        if fromLocationCode.isEmpty { return toLocationCode }
        if toLocationCode.isEmpty { return fromLocationCode }
        return "\(fromLocationCode) → \(toLocationCode)"
    }
}

/// Putaway queue grouping by status
struct PutawayQueueGroup: Identifiable {
    let id = UUID()
    let status: PutawayTaskStatus
    let count: Int
}

/// Status filter for putaway task list
enum PutawayTaskStatusFilter: String, CaseIterable, Identifiable {
    case all
    case pending
    case assigned
    case inProgress = "in_progress"
    case blocked
    case completed
    case cancelled

    var id: String { rawValue }

    var label: String {
        switch self {
        case .all: return "All"
        case .pending: return "Pending"
        case .assigned: return "Assigned"
        case .inProgress: return "In progress"
        case .blocked: return "Blocked"
        case .completed: return "Completed"
        case .cancelled: return "Cancelled"
        }
    }

    var apiStatus: String? {
        self == .all ? nil : rawValue
    }
}
