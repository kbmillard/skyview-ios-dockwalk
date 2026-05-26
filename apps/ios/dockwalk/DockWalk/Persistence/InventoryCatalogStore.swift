import Foundation
import Observation

/// Local inventory catalog for search, scan lookup, and receive-card autocomplete.
@Observable
final class InventoryCatalogStore {
    static let shared = InventoryCatalogStore()

    private static let persistenceKey = "SkyView.inventoryCatalogItems"

    private(set) var revision = 0
    private(set) var items: [InventoryItem] = []

    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        loadPersistedOrSeed()
    }

    func add(_ item: InventoryItem) {
        items.insert(item, at: 0)
        persist()
        bumpRevision()
    }

    /// Exact UPC match for scan-first putaway.
    func item(matchingUPC code: String) -> InventoryItem? {
        let trimmed = code.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return items.first {
            ($0.upc ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                .compare(trimmed, options: .caseInsensitive) == .orderedSame
        }
    }

    func search(query: String) -> [InventoryItem] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        let q = trimmed.lowercased()
        return items.filter { item in
            item.sku.lowercased().contains(q)
                || item.description.lowercased().contains(q)
                || item.location.lowercased().contains(q)
                || item.itemName.lowercased().contains(q)
                || (item.partDescription?.lowercased().contains(q) ?? false)
                || (item.upc?.lowercased().contains(q) ?? false)
        }
    }

    /// SKU field suggestions — match SKU only (never UPC).
    func suggestions(matchingSKU prefix: String, limit: Int = 5) -> [InventoryItem] {
        let q = prefix.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return [] }
        return items.filter { $0.sku.lowercased().contains(q) }
            .prefix(limit)
            .map { $0 }
    }

    func suggestions(matchingPartDescription prefix: String, limit: Int = 5) -> [InventoryItem] {
        let q = prefix.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return [] }
        return items.filter {
            ($0.partDescription?.lowercased().contains(q) ?? false)
        }
        .prefix(limit)
        .map { $0 }
    }

    private func loadPersistedOrSeed() {
        if let data = defaults.data(forKey: Self.persistenceKey),
           let decoded = try? decoder.decode([PersistedInventoryItem].self, from: data) {
            items = decoded.map(\.inventoryItem)
        } else {
            items = Self.demoSeed
            persist()
        }
    }

    private func persist() {
        let payload = items.map { PersistedInventoryItem(item: $0) }
        guard let data = try? encoder.encode(payload) else { return }
        defaults.set(data, forKey: Self.persistenceKey)
    }

    private func bumpRevision() {
        revision += 1
    }

    private static let demoSeed: [InventoryItem] = [
        InventoryItem(
            id: "inv-br-8821",
            sku: "BR-8821",
            upc: "012345678901",
            partDescription: "PRT-8821",
            itemName: "Brake Rotor Assembly",
            description: "Brake Rotor Assembly",
            quantity: 36,
            location: "A-14",
            status: .available,
            onHand: 36,
            reserved: 0
        ),
        InventoryItem(
            id: "inv-fl-2200",
            sku: "FL-2200",
            upc: "012345678902",
            partDescription: "PRT-2200",
            itemName: "Floor Mat Set",
            description: "Floor Mat Set",
            quantity: 120,
            location: "B-02",
            status: .available,
            onHand: 120,
            reserved: 4
        ),
        InventoryItem(
            id: "inv-wp-4410",
            sku: "WP-4410",
            upc: "012345678903",
            partDescription: "PRT-4410",
            itemName: "Windshield Panel",
            description: "Windshield Panel",
            quantity: 18,
            location: "C-08",
            status: .available,
            onHand: 18,
            reserved: 0
        ),
        InventoryItem(
            id: "inv-hd-9901",
            sku: "HD-9901",
            upc: "012345678904",
            partDescription: "PRT-9901",
            itemName: "Headlamp Housing",
            description: "Headlamp Housing",
            quantity: 42,
            location: "A-22",
            status: .reserved,
            onHand: 42,
            reserved: 12
        ),
    ]
}

// MARK: - Persistence DTO

private struct PersistedInventoryItem: Codable {
    let id: String
    let sku: String
    let upc: String?
    let partDescription: String?
    let itemName: String
    let description: String
    let quantity: Int
    let location: String
    let statusRaw: String
    let onHand: Int
    let reserved: Int

    enum CodingKeys: String, CodingKey {
        case id, sku, upc, itemName, description, quantity, location, statusRaw, onHand, reserved
        case partDescription
        case partNumber
    }

    init(item: InventoryItem) {
        id = item.id
        sku = item.sku
        upc = item.upc
        partDescription = item.partDescription
        itemName = item.itemName
        description = item.description
        quantity = item.quantity
        location = item.location
        statusRaw = item.status.rawValue
        onHand = item.onHand
        reserved = item.reserved
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        sku = try container.decode(String.self, forKey: .sku)
        upc = try container.decodeIfPresent(String.self, forKey: .upc)
        partDescription = try container.decodeIfPresent(String.self, forKey: .partDescription)
            ?? container.decodeIfPresent(String.self, forKey: .partNumber)
        itemName = try container.decode(String.self, forKey: .itemName)
        description = try container.decode(String.self, forKey: .description)
        quantity = try container.decode(Int.self, forKey: .quantity)
        location = try container.decode(String.self, forKey: .location)
        statusRaw = try container.decode(String.self, forKey: .statusRaw)
        onHand = try container.decode(Int.self, forKey: .onHand)
        reserved = try container.decode(Int.self, forKey: .reserved)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(sku, forKey: .sku)
        try container.encodeIfPresent(upc, forKey: .upc)
        try container.encodeIfPresent(partDescription, forKey: .partDescription)
        try container.encode(itemName, forKey: .itemName)
        try container.encode(description, forKey: .description)
        try container.encode(quantity, forKey: .quantity)
        try container.encode(location, forKey: .location)
        try container.encode(statusRaw, forKey: .statusRaw)
        try container.encode(onHand, forKey: .onHand)
        try container.encode(reserved, forKey: .reserved)
    }

    var inventoryItem: InventoryItem {
        InventoryItem(
            id: id,
            sku: sku,
            upc: upc,
            partDescription: partDescription,
            itemName: itemName,
            description: description,
            quantity: quantity,
            location: location,
            status: InventoryStatus(rawValue: statusRaw) ?? .available,
            onHand: onHand,
            reserved: reserved
        )
    }
}
