import Foundation
import Observation

@Observable
final class InventoryViewModel {
    var searchQuery = ""
    private(set) var items: [InventoryItem] = []
    private(set) var cycleCounts: [CycleCountTask] = []
    private(set) var recentMovements: [InventoryMovement] = []

    init() {
        loadStubData()
    }

    var filteredItems: [InventoryItem] {
        guard !searchQuery.trimmingCharacters(in: .whitespaces).isEmpty else {
            return []
        }
        let query = searchQuery.lowercased()
        return items.filter {
            $0.sku.lowercased().contains(query)
                || $0.description.lowercased().contains(query)
                || $0.location.lowercased().contains(query)
                || ($0.partNumber?.lowercased().contains(query) ?? false)
                || $0.itemName.lowercased().contains(query)
                || $0.status.displayName.lowercased().contains(query)
        }
    }
    
    var totalOnHandUnits: Int {
        items.reduce(0) { $0 + $1.onHand }
    }
    
    var totalReservedUnits: Int {
        items.reduce(0) { $0 + $1.reserved }
    }
    
    var totalAvailableUnits: Int {
        totalOnHandUnits - totalReservedUnits
    }

    private func loadStubData() {
        // Empty - all inventory will be created through user actions
        items = []
        recentMovements = []
        cycleCounts = []
    }
}
