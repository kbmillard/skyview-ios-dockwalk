import Foundation
import Observation

@Observable
final class OutboundViewModel {
    private(set) var allOrders: [OutboundOrder] = []
    private(set) var workflowGroups: [OutboundWorkflowGroup] = []
    private(set) var loadPhase: LoadPhase = .idle
    private(set) var dataMode: String?

    private let environment: AppEnvironment

    init(environment: AppEnvironment = .shared) {
        self.environment = environment
        #if DEBUG
        if FeatureFlags.allowFoundationDemoData {
            loadStubData()
        }
        #endif
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

    func load() async {
        loadPhase = .loading
        let apiClient = environment.makeAPIClient()

        do {
            let response = try await apiClient.fetchOutboundOrders(orgId: environment.orgId)
            dataMode = response.mode
            allOrders = response.items.map(OutboundAPIMapping.mapOrder)
            if allOrders.isEmpty {
                #if DEBUG
                if FeatureFlags.allowFoundationDemoData {
                    loadStubData()
                    dataMode = "foundation-demo"
                }
                #endif
            }
            buildWorkflowGroups()
            loadPhase = .loaded
        } catch {
            #if DEBUG
            if FeatureFlags.allowFoundationDemoData {
                loadStubData()
                dataMode = "foundation-demo"
                buildWorkflowGroups()
                loadPhase = .loaded
                return
            }
            #endif
            loadPhase = .error(message: "Can't load shipping orders right now.")
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

enum OutboundAPIMapping {
    private static let dateParser = ISO8601DateFormatter()

    static func mapOrder(_ dto: OutboundOrderDTO) -> OutboundOrder {
        let metadata = dto.metadata ?? [:]
        let customer = metadata["customer"]?.stringValue ?? "Customer"
        let door = metadata["door"]?.stringValue ?? ""
        let priorityRaw = metadata["priority"]?.stringValue?.lowercased() ?? "standard"
        let priority: OrderPriority = priorityRaw == "urgent" ? .urgent : .standard

        return OutboundOrder(
            id: dto.id,
            orderNumber: dto.orderNumber ?? dto.id,
            customer: customer,
            door: door,
            status: mapStatus(dto.status),
            lineCount: dto.lineCount ?? 0,
            cartonCount: dto.cartonCount ?? 0,
            priority: priority,
            shipDate: parseDate(dto.requestedShipAt),
            assignedTo: metadata["assigned_to"]?.stringValue
        )
    }

    static func mapLine(_ dto: OutboundLineDTO) -> OutboundLine {
        let metadata = dto.metadata ?? [:]
        let upc = dto.upc ?? metadata["upc"]?.stringValue ?? ""
        let location = metadata["location"]?.stringValue
        return OutboundLine(
            id: dto.id,
            sku: dto.sku ?? "",
            upc: upc,
            orderedQty: dto.orderedQty ?? 0,
            loadedQty: dto.loadedQty ?? 0,
            uom: dto.uom ?? "ea",
            status: dto.status ?? "open",
            location: location
        )
    }

    static func mapStatus(_ raw: String?) -> OutboundOrderStatus {
        guard let raw = raw?.lowercased() else { return .readyToPick }
        switch raw {
        case "ready_to_pick", "released", "draft":
            return .readyToPick
        case "picking":
            return .picking
        case "picked":
            return .picked
        case "staged":
            return .staged
        case "loading":
            return .loading
        case "shipped":
            return .shipped
        default:
            return .readyToPick
        }
    }

    static func parseDate(_ raw: String?) -> Date? {
        guard let raw else { return nil }
        return dateParser.date(from: raw)
    }
}
