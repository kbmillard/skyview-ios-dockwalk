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

    func removeItem(id: String) {
        receivedItems.removeAll { $0.id == id }
        persistItems()
    }

    func updateItem(_ item: ReceiveInventoryDraft) {
        guard let index = receivedItems.firstIndex(where: { $0.id == item.id }) else { return }
        receivedItems[index] = item
        persistItems()
    }

    func saveItem(id: String) -> Bool {
        guard let index = receivedItems.firstIndex(where: { $0.id == id }) else { return false }
        var item = receivedItems[index]
        guard Self.validate(item) else { return false }
        item.isSaved = true
        receivedItems[index] = item
        persistItems()
        return true
    }

    static func validate(_ item: ReceiveInventoryDraft) -> Bool {
        let sku = item.sku.trimmingCharacters(in: .whitespaces)
        let qty = Int(item.quantity.trimmingCharacters(in: .whitespaces)) ?? 0
        return !sku.isEmpty && qty > 0
    }

    var savedItemCount: Int {
        receivedItems.filter(\.isSaved).count
    }
}
