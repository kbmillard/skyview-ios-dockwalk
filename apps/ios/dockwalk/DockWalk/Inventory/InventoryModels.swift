import Foundation

struct InventoryItem: Identifiable, Equatable {
    let id: String
    let sku: String
    let upc: String?
    let partNumber: String?
    let itemName: String
    let description: String
    var quantity: Int
    var location: String
    var status: InventoryStatus
    let onHand: Int
    let reserved: Int
}

enum InventoryStatus: String, CaseIterable {
    case available = "Available"
    case reserved = "Reserved"
    case onHold = "On Hold"
    case damaged = "Damaged"
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
