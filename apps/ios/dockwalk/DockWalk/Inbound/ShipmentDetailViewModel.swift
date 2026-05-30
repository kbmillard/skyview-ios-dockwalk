import Foundation
import Observation

@Observable
final class ShipmentDetailViewModel {
    let loadId: String

    private(set) var receivedItems: [ReceiveInventoryDraft] = []
    private(set) var loadPhase: LoadPhase = .idle
    private(set) var dataMode: String?

    private let environment: AppEnvironment
    private let session: InboundSessionStore

    init(
        loadId: String,
        environment: AppEnvironment = .shared,
        session: InboundSessionStore = .shared
    ) {
        self.loadId = loadId
        self.environment = environment
        self.session = session
    }

    func load() async {
        loadPhase = .loading
        receivedItems = session.receivedItems(for: loadId)
        dataMode = FeatureFlags.foundationInboundDemoEnabled ? "foundation-demo" : "local"
        loadPhase = .loaded
    }

    func persistItems() {
        session.saveReceivedItems(loadId: loadId, items: receivedItems)
    }

    func addFromScan(_ code: String) {
        receivedItems.insert(ReceiveInventoryDraft.fromScan(code), at: 0)
        persistItems()
    }

    func addEmptyCard() {
        receivedItems.insert(ReceiveInventoryDraft.empty(), at: 0)
        persistItems()
    }
    
    func addItem(_ item: ReceiveInventoryDraft) {
        receivedItems.insert(item, at: 0)
        persistItems()
    }

    func removeItem(id: String) {
        receivedItems.removeAll { $0.id == id }
        persistItems()
    }

    func updateItem(_ item: ReceiveInventoryDraft) {
        guard let index = receivedItems.firstIndex(where: { $0.id == item.id }) else { return }
        receivedItems[index] = item
        persistItems()
    }

    func item(id: String) -> ReceiveInventoryDraft? {
        receivedItems.first(where: { $0.id == id })
    }

    func saveItem(id: String) -> Bool {
        guard let index = receivedItems.firstIndex(where: { $0.id == id }) else { return false }
        var item = receivedItems[index]
        guard Self.validate(item) else { return false }
        item.quantity = ""
        item.isSaved = true
        receivedItems[index] = item
        persistItems()
        return true
    }

    static func validate(_ item: ReceiveInventoryDraft) -> Bool {
        let hasName = !item.itemName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasLocation = !item.location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        return item.hasIdentifier && hasName && hasLocation && item.hasQuantityInput && item.committedQuantity > 0
    }

    func templateItem(forSKU sku: String) -> ReceiveInventoryDraft? {
        receivedItems
            .filter { $0.isSaved && $0.sku == sku }
            .last
    }

    var savedItemCount: Int {
        receivedItems.filter(\.isSaved).count
    }
    
    var totalUPCs: Int {
        receivedItems.filter { $0.isSaved && !$0.upc.isEmpty }.count
    }
    
    var totalCases: Int {
        receivedItems.filter(\.isSaved).compactMap(\.parsedCases).reduce(0, +)
    }
    
    var totalEaches: Int {
        receivedItems.filter(\.isSaved).map(\.committedQuantity).reduce(0, +)
    }
    
    var uniqueSKUs: Int {
        Set(receivedItems.filter { $0.isSaved && !$0.sku.isEmpty }.map(\.sku)).count
    }
    
    var skuGroups: [ReceiveSKUGroup] {
        let saved = receivedItems.filter { $0.isSaved && !$0.sku.isEmpty }
        let uniqueSKUs = Set(saved.map(\.sku)).sorted()
        return uniqueSKUs.compactMap { sku in
            let lines = saved.filter { $0.sku == sku }
            guard let first = lines.first else { return nil }
            let upcLines = lines.map { item in
                ReceiveUPCLine(
                    id: item.id,
                    upc: item.upc.isEmpty ? "—" : item.upc,
                    quantityLabel: item.upcLineQuantityLabel,
                    location: item.location,
                    status: item.status
                )
            }
            return ReceiveSKUGroup(
                sku: sku,
                name: first.itemName,
                description: first.partDescription,
                upcLines: upcLines
            )
        }
    }
}
