import Foundation

/// Dock door status for WMS operations
struct DockDoorStatus: Identifiable, Equatable {
    let id: String
    let doorNumber: String
    let status: DoorStatus
    let assignedLoad: String?
    
    enum DoorStatus: String {
        case open
        case occupied
        
        var displayName: String {
            switch self {
            case .open: return "Open"
            case .occupied: return "Occupied"
            }
        }
        
        var chipTone: StatusChip.Tone {
            switch self {
            case .open: return .success
            case .occupied: return .warning
            }
        }
    }
}

/// Inbound load grouped by workflow status
struct InboundLoadGroup: Identifiable {
    let id = UUID()
    let status: InboundLoadStatus
    let count: Int
    let loads: [InboundLoad]
}

/// Individual inbound load
struct InboundLoad: Identifiable, Equatable {
    let id: String
    let referenceNumber: String
    let carrier: String?
    let status: InboundLoadStatus
    let scheduledAt: Date?
    let doorAssignment: String?
}

/// Putaway queue grouped by workflow status
struct PutawayQueueGroup: Identifiable {
    let id = UUID()
    let status: PutawayQueueStatus
    let count: Int
}

enum PutawayQueueStatus: String, CaseIterable {
    case staged = "pending"
    case assigned = "assigned"
    case inProgress = "in_progress"
    case blocked = "blocked"
    case complete = "completed"
    
    var displayName: String {
        switch self {
        case .staged: return "Staged / Pending"
        case .assigned: return "Assigned"
        case .inProgress: return "In Progress"
        case .blocked: return "Blocked"
        case .complete: return "Complete"
        }
    }
    
    var systemImage: String {
        switch self {
        case .staged: return "square.stack"
        case .assigned: return "person.crop.circle"
        case .inProgress: return "arrow.triangle.2.circlepath"
        case .blocked: return "exclamationmark.triangle"
        case .complete: return "checkmark.circle"
        }
    }
    
    var chipTone: StatusChip.Tone {
        switch self {
        case .staged: return .neutral
        case .assigned: return .info
        case .inProgress: return .info
        case .blocked: return .warning
        case .complete: return .success
        }
    }
}
