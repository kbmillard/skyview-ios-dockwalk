import Foundation

enum OutboundOrderStatus: String, CaseIterable {
    case readyToPick = "ready_to_pick"
    case picking
    case picked
    case staged
    case loading
    case shipped

    var displayName: String {
        switch self {
        case .readyToPick: return "Ready to pick"
        case .picking: return "Picking"
        case .picked: return "Picked"
        case .staged: return "Staged"
        case .loading: return "Loading"
        case .shipped: return "Shipped"
        }
    }

    var chipTone: StatusChip.Tone {
        switch self {
        case .readyToPick: return .neutral
        case .picking: return .info
        case .picked: return .info
        case .staged: return .neutral
        case .loading: return .warning
        case .shipped: return .success
        }
    }
    
    var systemImage: String {
        switch self {
        case .readyToPick: return "cart"
        case .picking: return "cart.fill"
        case .picked: return "checkmark.circle"
        case .staged: return "square.stack.3d.up"
        case .loading: return "truck.box.fill"
        case .shipped: return "checkmark.seal.fill"
        }
    }
}

struct OutboundOrder: Identifiable, Equatable {
    let id: String
    let orderNumber: String
    let customer: String
    let door: String
    let status: OutboundOrderStatus
    let lineCount: Int
    let cartonCount: Int
    let priority: OrderPriority
    let shipDate: Date?
    let assignedTo: String?
}

enum OrderPriority: String, Equatable {
    case standard, urgent
    
    var displayName: String {
        switch self {
        case .standard: return "Standard"
        case .urgent: return "Urgent"
        }
    }
    
    var chipTone: StatusChip.Tone {
        switch self {
        case .standard: return .neutral
        case .urgent: return .warning
        }
    }
}

struct OutboundWorkflowGroup: Identifiable {
    let id: String
    let status: OutboundOrderStatus
    let count: Int
    let orders: [OutboundOrder]
}
