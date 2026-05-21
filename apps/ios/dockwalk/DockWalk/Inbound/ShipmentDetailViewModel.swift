import Foundation
import Observation

@Observable
final class ShipmentDetailViewModel {
    let load: ReceivingAppointment

    private(set) var receivedItems: [ReceiveInventoryDraft] = []
    private(set) var loadPhase: LoadPhase = .idle
    private(set) var dataMode: String?

    private let environment: AppEnvironment

    init(
        load: ReceivingAppointment,
        environment: AppEnvironment = .shared
    ) {
        self.load = load
        self.environment = environment
    }

    /// Receive work mode uses local capture only — no shipment lines API.
    func load() async {
        loadPhase = .loading
        receivedItems = []
        dataMode = FeatureFlags.foundationInboundDemoEnabled ? "foundation-demo" : "local"
        loadPhase = .loaded
    }

    func addFromScan(_ code: String) {
        receivedItems.insert(ReceiveInventoryDraft.fromScan(code), at: 0)
    }

    func addEmptyCard() {
        receivedItems.insert(ReceiveInventoryDraft.empty(), at: 0)
    }

    func removeItem(id: String) {
        receivedItems.removeAll { $0.id == id }
    }

    func updateItem(_ item: ReceiveInventoryDraft) {
        guard let index = receivedItems.firstIndex(where: { $0.id == item.id }) else { return }
        receivedItems[index] = item
    }
}
