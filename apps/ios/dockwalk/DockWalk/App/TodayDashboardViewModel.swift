import Foundation
import Observation

@Observable
final class TodayDashboardViewModel {
    // Inbound workflow
    private(set) var inboundGroups: [InboundLoadGroup] = []
    private(set) var dockDoors: [DockDoorStatus] = []
    
    // Putaway workflow
    private(set) var putawayGroups: [PutawayQueueGroup] = []
    private(set) var totalPutawayTasks: Int = 0
    
    // Outbound summary (foundation data)
    private(set) var readyToPickCount: Int = 0
    private(set) var pickingCount: Int = 0
    private(set) var loadingCount: Int = 0
    
    // Inventory summary (foundation data)
    private(set) var inventorySkuCount: Int = 0
    private(set) var inventoryTotalUnits: Int = 0
    
    // Load state
    private(set) var loadPhase: LoadPhase = .idle
    private var hasLoadedOnce = false

    private let environment: AppEnvironment

    init(environment: AppEnvironment = .shared) {
        self.environment = environment
        loadFoundationSummaryData()
    }

    func refresh() async {
        loadPhase = .loading
        let apiClient = environment.makeAPIClient()
        let orgId = environment.orgId

        do {
            // Fetch appointments for inbound workflow
            async let appointmentsResponse: APIListResponse<AppointmentDTO> = apiClient.get(
                .appointments(orgId: orgId)
            )
            
            // Fetch putaway tasks for queue grouping
            async let tasksResponse = apiClient.fetchTasks(
                orgId: orgId,
                taskType: PutawayTasksViewModel.taskTypePutaway,
                status: nil,
                inboundShipmentId: nil,
                limit: 100,
                offset: 0
            )
            
            let appointments = try await appointmentsResponse
            let tasks = try await tasksResponse

            // Process inbound workflow groups
            inboundGroups = processInboundGroups(from: appointments.items)
            
            // Process putaway queue groups
            putawayGroups = processPutawayGroups(from: tasks.items)
            totalPutawayTasks = tasks.pagination.total
            
            // Load stable dock door foundation data
            dockDoors = loadDockDoorFoundationData()
            
            loadPhase = .loaded
            hasLoadedOnce = true
        } catch {
            // Preserve existing data on error if we've loaded before
            if !hasLoadedOnce {
                inboundGroups = []
                putawayGroups = []
                dockDoors = []
            }
            loadPhase = .error(message: userFacingError(error))
        }
    }
    
    // MARK: - Data Processing
    
    private func processInboundGroups(from appointments: [AppointmentDTO]) -> [InboundLoadGroup] {
        let loads = appointments.map { apt in
            InboundLoad(
                id: apt.id,
                referenceNumber: apt.referenceNumber ?? apt.id,
                carrier: nil,
                status: inferInboundStatus(from: apt.status),
                scheduledAt: parseDate(apt.scheduledAt),
                doorAssignment: nil
            )
        }
        
        var groups: [InboundLoadGroup] = []
        
        for status in InboundStatus.allCases {
            let filtered = loads.filter { $0.status == status }
            if !filtered.isEmpty || status == .scheduled || status == .checkedIn {
                groups.append(InboundLoadGroup(
                    status: status,
                    count: filtered.count,
                    loads: filtered
                ))
            }
        }
        
        return groups
    }
    
    private func processPutawayGroups(from tasks: [WarehouseTaskDTO]) -> [PutawayQueueGroup] {
        var groups: [PutawayQueueGroup] = []
        
        for status in PutawayQueueStatus.allCases {
            let count = tasks.filter { $0.status == status.rawValue }.count
            groups.append(PutawayQueueGroup(status: status, count: count))
        }
        
        return groups.filter { $0.count > 0 || $0.status == .staged || $0.status == .assigned }
    }
    
    private func inferInboundStatus(from apiStatus: String?) -> InboundStatus {
        guard let apiStatus else { return .scheduled }
        
        switch apiStatus.lowercased() {
        case "arrived": return .checkedIn
        case "staged": return .staged
        case "receiving": return .receiving
        default: return .scheduled
        }
    }
    
    private func parseDate(_ dateString: String?) -> Date? {
        guard let dateString else { return nil }
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: dateString)
    }
    
    // MARK: - Foundation Data
    
    private func loadDockDoorFoundationData() -> [DockDoorStatus] {
        // Stable local foundation data for dock doors
        // No live API route yet - this is intentional preview structure
        return [
            DockDoorStatus(id: "door-1", doorNumber: "Door 1", status: .open, assignedLoad: nil),
            DockDoorStatus(id: "door-2", doorNumber: "Door 2", status: .occupied, assignedLoad: "APT-1002"),
            DockDoorStatus(id: "door-3", doorNumber: "Door 3", status: .open, assignedLoad: nil),
            DockDoorStatus(id: "door-4", doorNumber: "Door 4", status: .open, assignedLoad: nil),
        ]
    }
    
    private func loadFoundationSummaryData() {
        // Load stable outbound summary from foundation data
        // This matches the stub data in OutboundViewModel
        let outboundViewModel = OutboundViewModel()
        readyToPickCount = outboundViewModel.readyToPickCount
        pickingCount = outboundViewModel.pickingCount
        loadingCount = outboundViewModel.activeLoadsCount
        
        // Load stable inventory summary from foundation data
        // This matches the stub data in InventoryViewModel
        let inventoryViewModel = InventoryViewModel()
        inventorySkuCount = inventoryViewModel.items.count
        inventoryTotalUnits = inventoryViewModel.totalOnHandUnits
    }

    private func userFacingError(_ error: Error) -> String {
        if let apiError = error as? APIClientError {
            return apiError.errorDescription ?? "Could not load dashboard."
        }
        return error.localizedDescription
    }
}
