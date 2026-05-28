import Foundation
import Observation

@Observable
final class PickingTasksViewModel {
    private(set) var tasks: [PickTask] = []
    var searchQuery = ""
    
    init() {
        #if DEBUG
        if FeatureFlags.allowFoundationDemoData {
            loadStubData()
        }
        #endif
    }
    
    var summary: PickTaskSummary {
        PickTaskSummary(
            readyToPickCount: tasks.filter { $0.status == .readyToPick }.count,
            assignedCount: tasks.filter { $0.status == .assigned }.count,
            pickingCount: tasks.filter { $0.status == .picking }.count,
            pickedCount: tasks.filter { $0.status == .picked }.count,
            blockedCount: tasks.filter { $0.status == .blocked }.count,
            totalLines: tasks.reduce(0) { $0 + $1.lines.count },
            totalQuantity: tasks.reduce(0) { $0 + $1.lines.reduce(0) { $0 + $1.quantityOrdered } }
        )
    }
    
    var readyToPickTasks: [PickTask] {
        filteredTasks.filter { $0.status == .readyToPick }
    }
    
    var assignedTasks: [PickTask] {
        filteredTasks.filter { $0.status == .assigned }
    }
    
    var pickingTasks: [PickTask] {
        filteredTasks.filter { $0.status == .picking }
    }
    
    var pickedTasks: [PickTask] {
        filteredTasks.filter { $0.status == .picked }
    }
    
    var blockedTasks: [PickTask] {
        filteredTasks.filter { $0.status == .blocked }
    }
    
    private var filteredTasks: [PickTask] {
        guard !searchQuery.trimmingCharacters(in: .whitespaces).isEmpty else {
            return tasks
        }
        let query = searchQuery.lowercased()
        return tasks.filter {
            $0.orderNumber.lowercased().contains(query)
                || $0.customer.lowercased().contains(query)
                || $0.shipmentId.lowercased().contains(query)
        }
    }
    
    private func loadStubData() {
        let now = Date()
        
        tasks = [
            PickTask(
                id: "pick-1",
                shipmentId: "S-55120",
                orderNumber: "ORD-8821",
                customer: "Midwest Supply",
                status: .readyToPick,
                priority: .standard,
                dueDate: now.addingTimeInterval(86400),
                lines: [
                    PickLine(
                        id: "pl-1",
                        taskId: "pick-1",
                        sku: "BR-8821",
                        upc: "00938122",
                        partDescription: "AUTO-BR-01",
                        itemName: "Brake Rotor Assembly",
                        description: "Brake Rotor Assembly",
                        fromLocation: "A-14",
                        quantityOrdered: 12,
                        quantityPicked: 0,
                        status: .pending
                    ),
                    PickLine(
                        id: "pl-2",
                        taskId: "pick-1",
                        sku: "SKU-44102",
                        upc: "00844711002",
                        partDescription: "BEV-CS-01",
                        itemName: "Cases — beverage",
                        description: "Cases — beverage",
                        fromLocation: "A-12-03",
                        quantityOrdered: 48,
                        quantityPicked: 0,
                        status: .pending
                    ),
                ],
                assignedTo: nil,
                createdAt: now.addingTimeInterval(-7200),
                updatedAt: now.addingTimeInterval(-7200)
            ),
            PickTask(
                id: "pick-2",
                shipmentId: "S-55132",
                orderNumber: "ORD-8830",
                customer: "Northern Distribution",
                status: .assigned,
                priority: .expedited,
                dueDate: now.addingTimeInterval(43200),
                lines: [
                    PickLine(
                        id: "pl-3",
                        taskId: "pick-2",
                        sku: "SKU-99201",
                        upc: "00992010001",
                        partDescription: "CHEM-DR-01",
                        itemName: "Drums — chemical",
                        description: "Drums — chemical",
                        fromLocation: "C-04-01",
                        quantityOrdered: 6,
                        quantityPicked: 0,
                        status: .pending
                    ),
                ],
                assignedTo: "Current User",
                createdAt: now.addingTimeInterval(-3600),
                updatedAt: now.addingTimeInterval(-1800)
            ),
            PickTask(
                id: "pick-3",
                shipmentId: "S-55140",
                orderNumber: "ORD-8835",
                customer: "Southern Wholesale",
                status: .picking,
                priority: .rush,
                dueDate: now.addingTimeInterval(21600),
                lines: [
                    PickLine(
                        id: "pl-4",
                        taskId: "pick-3",
                        sku: "SKU-22018",
                        upc: "00220180001",
                        partDescription: "RET-PAL-01",
                        itemName: "Pallet — mixed retail",
                        description: "Pallet — mixed retail",
                        fromLocation: "B-08-02",
                        quantityOrdered: 24,
                        quantityPicked: 12,
                        status: .picking
                    ),
                ],
                assignedTo: "Current User",
                createdAt: now.addingTimeInterval(-1800),
                updatedAt: now.addingTimeInterval(-300)
            ),
        ]
    }
}
