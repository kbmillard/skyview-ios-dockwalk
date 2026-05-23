import Foundation

struct InventoryItem: Identifiable, Equatable {
    let id: String
    let sku: String
    let upc: String?
    let partDescription: String?
    let itemName: String
    let description: String
    var quantity: Int
    var location: String
    var status: InventoryStatus
    let onHand: Int
    let reserved: Int
}

enum InventoryStatus: String, CaseIterable, Codable {
    case available = "available"
    case reserved = "reserved"
    case onHold = "on_hold"
    case damaged = "damaged"
    
    var displayName: String {
        switch self {
        case .available: return "Available"
        case .reserved: return "Reserved"
        case .onHold: return "On Hold"
        case .damaged: return "Damaged"
        }
    }
    
    var chipTone: StatusChip.Tone {
        switch self {
        case .available: return .success
        case .reserved: return .neutral
        case .onHold: return .warning
        case .damaged: return .danger
        }
    }
    
    var systemImage: String {
        switch self {
        case .available: return "checkmark.circle"
        case .reserved: return "lock"
        case .onHold: return "pause.circle"
        case .damaged: return "exclamationmark.triangle"
        }
    }
}

// MARK: - WorkflowStatus Conformance
extension InventoryStatus: WorkflowStatus {
    var id: String { rawValue }
    
    var sortOrder: Int {
        switch self {
        case .available: return 0
        case .reserved: return 1
        case .onHold: return 2
        case .damaged: return 3
        }
    }
}

struct CycleCountTask: Identifiable, Equatable {
    let id: String
    let zone: String
    let locationsRemaining: Int
}

struct InventoryMovement: Identifiable, Equatable {
    let id: String
    let sku: String
    let fromLocation: String
    let toLocation: String
    let quantity: Int
    let timestamp: Date
}
