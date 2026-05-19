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
                || ($0.upc?.lowercased().contains(query) ?? false)
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
        items = [
            InventoryItem(
                id: "inv-1",
                sku: "SKU-44102",
                upc: "00844711002",
                partNumber: "BEV-CS-01",
                itemName: "Cases — beverage",
                description: "Cases — beverage",
                quantity: 480,
                location: "A-12-03",
                status: .reserved,
                onHand: 480,
                reserved: 48
            ),
            InventoryItem(
                id: "inv-2",
                sku: "SKU-99201",
                upc: "00992010001",
                partNumber: "CHEM-DR-01",
                itemName: "Drums — chemical",
                description: "Drums — chemical",
                quantity: 36,
                location: "C-04-01",
                status: .available,
                onHand: 36,
                reserved: 0
            ),
            InventoryItem(
                id: "inv-3",
                sku: "SKU-22018",
                upc: "00220180001",
                partNumber: "RET-PAL-01",
                itemName: "Pallet — mixed retail",
                description: "Pallet — mixed retail",
                quantity: 120,
                location: "B-08-02",
                status: .reserved,
                onHand: 120,
                reserved: 24
            ),
            InventoryItem(
                id: "inv-4",
                sku: "BR-8821",
                upc: "00938122",
                partNumber: "AUTO-BR-01",
                itemName: "Brake Rotor Assembly",
                description: "Brake Rotor Assembly",
                quantity: 36,
                location: "A-14",
                status: .available,
                onHand: 36,
                reserved: 0
            ),
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
