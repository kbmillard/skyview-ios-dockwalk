import Foundation
import Observation

@Observable
final class OutboundViewModel {
    private(set) var stagedOrders: [OutboundOrder] = []
    private(set) var activeLoads = 2

    init() {
        loadStubData()
    }

    private func loadStubData() {
        stagedOrders = [
            OutboundOrder(id: "out-101", customer: "Regional Foods", door: "Door 8", status: .loading, cartonCount: 142),
            OutboundOrder(id: "out-102", customer: "AutoParts Direct", door: "Door 4", status: .picking, cartonCount: 88),
            OutboundOrder(id: "out-103", customer: "BuildRight Supply", door: "Door 11", status: .staged, cartonCount: 56),
            OutboundOrder(id: "out-104", customer: "Coastal Retail", door: "Door 2", status: .readyToClose, cartonCount: 210),
        ]
    }
}
