import Foundation
import Observation

@Observable
final class InventoryViewModel {
    var searchQuery = ""
    private(set) var cycleCounts: [CycleCountTask] = []
    private(set) var recentMovements: [InventoryMovement] = []

    private let catalog: InventoryCatalogStore

    init(catalog: InventoryCatalogStore = .shared) {
        self.catalog = catalog
        cycleCounts = []
        recentMovements = []
    }

    var items: [InventoryItem] {
        catalog.items
    }

    var filteredItems: [InventoryItem] {
        catalog.search(query: searchQuery)
    }

    var hasSearchQuery: Bool {
        !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var isScannedCodeNotFound: Bool {
        hasSearchQuery && filteredItems.isEmpty
    }

    func addItem(_ item: InventoryItem) {
        catalog.add(item)
    }

    func refreshFromCatalog() {
        let _ = catalog.revision
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
}
