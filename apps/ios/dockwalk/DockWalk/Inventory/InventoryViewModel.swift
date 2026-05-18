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
            return items
        }
        let query = searchQuery.lowercased()
        return items.filter {
            $0.sku.lowercased().contains(query)
                || $0.description.lowercased().contains(query)
                || $0.location.lowercased().contains(query)
        }
    }

    private func loadStubData() {
        items = [
            InventoryItem(id: "inv-1", sku: "SKU-44102", description: "Cases — beverage", location: "A-12-03", onHand: 480, reserved: 48),
            InventoryItem(id: "inv-2", sku: "SKU-99201", description: "Drums — chemical", location: "C-04-01", onHand: 36, reserved: 0),
            InventoryItem(id: "inv-3", sku: "SKU-22018", description: "Pallet — mixed retail", location: "B-08-02", onHand: 120, reserved: 24),
        ]
        
        recentMovements = [
            InventoryMovement(
                id: "mv-1",
                sku: "SKU-44102",
                fromLocation: "RECV-STAGE",
                toLocation: "A-12-03",
                quantity: 48,
                timestamp: Date().addingTimeInterval(-3600)
            ),
            InventoryMovement(
                id: "mv-2",
                sku: "SKU-22018",
                fromLocation: "RECV-STAGE",
                toLocation: "B-08-02",
                quantity: 24,
                timestamp: Date().addingTimeInterval(-7200)
            ),
        ]
        
        cycleCounts = [
            CycleCountTask(id: "cc-1", zone: "Zone A", locationsRemaining: 14),
            CycleCountTask(id: "cc-2", zone: "Zone C — hazmat", locationsRemaining: 6),
        ]
    }
}
