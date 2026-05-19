import Foundation
import Observation

@Observable
final class OutboundViewModel {
    private(set) var allOrders: [OutboundOrder] = []
    private(set) var workflowGroups: [OutboundWorkflowGroup] = []

    init() {
        loadStubData()
        buildWorkflowGroups()
    }
    
    var readyToPickOrders: [OutboundOrder] {
        allOrders.filter { $0.status == .readyToPick }
    }
    
    var pickingOrders: [OutboundOrder] {
        allOrders.filter { $0.status == .picking }
    }
    
    var pickedOrders: [OutboundOrder] {
        allOrders.filter { $0.status == .picked }
    }
    
    var stagedOrders: [OutboundOrder] {
        allOrders.filter { $0.status == .staged }
    }
    
    var loadingOrders: [OutboundOrder] {
        allOrders.filter { $0.status == .loading }
    }
    
    var shippedOrders: [OutboundOrder] {
        allOrders.filter { $0.status == .shipped }
    }
    
    var activeWorkOrders: [OutboundOrder] {
        allOrders.filter { $0.status != .shipped }
    }
    
    var activeLoadsCount: Int {
        loadingOrders.count
    }
    
    var stagedCount: Int {
        stagedOrders.count
    }
    
    var pickingCount: Int {
        pickingOrders.count + pickedOrders.count
    }
    
    var readyToPickCount: Int {
        readyToPickOrders.count
    }

    private func buildWorkflowGroups() {
        let statuses: [OutboundOrderStatus] = [.readyToPick, .picking, .picked, .staged, .loading]
        workflowGroups = statuses.compactMap { status in
            let orders = allOrders.filter { $0.status == status }
            guard !orders.isEmpty else { return nil }
            return OutboundWorkflowGroup(
                id: status.rawValue,
                status: status,
                count: orders.count,
                orders: orders
            )
        }
    }

    private func loadStubData() {
        let today = Date()
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        
        allOrders = [
            OutboundOrder(
                id: "out-101",
                orderNumber: "SO-4401",
                customer: "Regional Foods",
                door: "Door 8",
                status: .loading,
                lineCount: 24,
                cartonCount: 142,
                priority: .standard,
                shipDate: today,
                assignedTo: "Loader-3"
            ),
            OutboundOrder(
                id: "out-102",
                orderNumber: "SO-4402",
                customer: "AutoParts Direct",
                door: "Door 4",
                status: .picking,
                lineCount: 18,
                cartonCount: 88,
                priority: .urgent,
                shipDate: today,
                assignedTo: "Picker-2"
            ),
            OutboundOrder(
                id: "out-ship",
                orderNumber: "S-55120",
                customer: "Midwest Supply",
                door: "Door 2",
                status: .staged,
                lineCount: 14,
                cartonCount: 14,
                priority: .urgent,
                shipDate: today,
                assignedTo: nil
            ),
            OutboundOrder(
                id: "out-104",
                orderNumber: "SO-4404",
                customer: "Coastal Retail",
                door: "",
                status: .picked,
                lineCount: 32,
                cartonCount: 210,
                priority: .standard,
                shipDate: tomorrow,
                assignedTo: "Picker-1"
            ),
            OutboundOrder(
                id: "out-105",
                orderNumber: "SO-4405",
                customer: "Metro Hardware",
                door: "",
                status: .readyToPick,
                lineCount: 14,
                cartonCount: 64,
                priority: .urgent,
                shipDate: today,
                assignedTo: nil
            ),
            OutboundOrder(
                id: "out-106",
                orderNumber: "SO-4406",
                customer: "Valley Distributing",
                door: "",
                status: .readyToPick,
                lineCount: 8,
                cartonCount: 42,
                priority: .standard,
                shipDate: tomorrow,
                assignedTo: nil
            ),
        ]
    }
}
