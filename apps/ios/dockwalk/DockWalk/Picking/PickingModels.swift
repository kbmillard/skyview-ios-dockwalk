import Foundation

struct PickTask: Identifiable, Codable, Equatable {
    let id: String
    let shipmentId: String
    let orderNumber: String
    let customer: String
    var status: PickTaskStatus
    let priority: PickPriority
    let dueDate: Date?
    var lines: [PickLine]
    var assignedTo: String?
    let createdAt: Date
    var updatedAt: Date
}

struct PickLine: Identifiable, Codable, Equatable {
    let id: String
    let taskId: String
    let sku: String
    let upc: String?
    let partDescription: String?
    let itemName: String
    let description: String
    let fromLocation: String
    var quantityOrdered: Int
    var quantityPicked: Int
    var status: PickLineStatus
    var scannedAt: Date?
}

enum PickTaskStatus: String, Codable, CaseIterable {
    case readyToPick = "ready_to_pick"
    case assigned = "assigned"
    case picking = "picking"
    case picked = "picked"
    case staged = "staged"
    case blocked = "blocked"
    case complete = "completed"
    case cancelled = "cancelled"
    
    var displayName: String {
        switch self {
        case .readyToPick: return "Ready to Pick"
        case .assigned: return "Assigned"
        case .picking: return "Picking"
        case .picked: return "Picked"
        case .staged: return "Staged"
        case .blocked: return "Blocked"
        case .complete: return "Complete"
        case .cancelled: return "Cancelled"
        }
    }
    
    var chipTone: StatusChip.Tone {
        switch self {
        case .readyToPick: return .neutral
        case .assigned: return .info
        case .picking: return .warning
        case .picked: return .info
        case .staged: return .neutral
        case .blocked: return .danger
        case .complete: return .success
        case .cancelled: return .neutral
        }
    }
    
    var systemImage: String {
        switch self {
        case .readyToPick: return "cart"
        case .assigned: return "person.crop.circle"
        case .picking: return "cart.fill"
        case .picked: return "checkmark.circle"
        case .staged: return "square.stack"
        case .blocked: return "exclamationmark.triangle"
        case .complete: return "checkmark.seal.fill"
        case .cancelled: return "xmark.circle"
        }
    }
}

// MARK: - WorkflowStatus Conformance
extension PickTaskStatus: WorkflowStatus {
    var id: String { rawValue }
    
    var sortOrder: Int {
        switch self {
        case .readyToPick: return 0
        case .assigned: return 1
        case .picking: return 2
        case .picked: return 3
        case .staged: return 4
        case .blocked: return 5
        case .complete: return 6
        case .cancelled: return 7
        }
    }
}

enum PickLineStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case picking = "picking"
    case picked = "picked"
    case short = "short"
    case damaged = "damaged"
    case notFound = "not_found"
    
    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .picking: return "Picking"
        case .picked: return "Picked"
        case .short: return "Short"
        case .damaged: return "Damaged"
        case .notFound: return "Not Found"
        }
    }
    
    var chipTone: StatusChip.Tone {
        switch self {
        case .pending: return .neutral
        case .picking: return .warning
        case .picked: return .success
        case .short: return .warning
        case .damaged: return .danger
        case .notFound: return .danger
        }
    }
}

enum PickPriority: String, Codable, CaseIterable {
    case standard = "standard"
    case expedited = "expedited"
    case rush = "rush"
    
    var displayName: String {
        switch self {
        case .standard: return "Standard"
        case .expedited: return "Expedited"
        case .rush: return "Rush"
        }
    }
    
    var chipTone: StatusChip.Tone {
        switch self {
        case .standard: return .neutral
        case .expedited: return .warning
        case .rush: return .danger
        }
    }
    
    var systemImage: String {
        switch self {
        case .standard: return "clock"
        case .expedited: return "clock.badge.exclamationmark"
        case .rush: return "bolt.fill"
        }
    }
}

struct PickTaskSummary {
    let readyToPickCount: Int
    let assignedCount: Int
    let pickingCount: Int
    let pickedCount: Int
    let blockedCount: Int
    let totalLines: Int
    let totalQuantity: Int
}
