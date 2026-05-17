import Foundation

struct InventoryItem: Identifiable, Equatable {
    let id: String
    let sku: String
    let description: String
    let location: String
    let onHand: Int
    let reserved: Int
}

struct CycleCountTask: Identifiable, Equatable {
    let id: String
    let zone: String
    let locationsRemaining: Int
}
