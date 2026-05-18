import Foundation
import Observation

@Observable
final class OutboundViewModel {
    private(set) var allOrders: [OutboundOrder] = []

    init() {
        loadStubData()
    }
    
    var loadingOrders: [OutboundOrder] {
        allOrders.filter { $0.status == .loading }
    }
    
    var pickingAndStagedOrders: [OutboundOrder] {
        allOrders.filter { $0.status == .picking || $0.status == .staged }
    }
    
    var readyToCloseOrders: [OutboundOrder] {
        allOrders.filter { $0.status == .readyToClose }
    }
    
    var activeLoadsCount: Int {
        loadingOrders.count
    }
    
    var stagedCount: Int {
        allOrders.filter { $0.status == .staged }.count
    }
    
    var pickingCount: Int {
        allOrders.filter { $0.status == .picking }.count
    }

    private func loadStubData() {
        allOrders = [
            OutboundOrder(id: "out-101", customer: "Regional Foods", door: "Door 8", status: .loading, cartonCount: 142),
            OutboundOrder(id: "out-102", customer: "AutoParts Direct", door: "Door 4", status: .picking, cartonCount: 88),
            OutboundOrder(id: "out-103", customer: "BuildRight Supply", door: "Door 11", status: .staged, cartonCount: 56),
            OutboundOrder(id: "out-104", customer: "Coastal Retail", door: "Door 2", status: .readyToClose, cartonCount: 210),
        ]
    }
}
