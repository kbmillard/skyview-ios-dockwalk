import Foundation
import Observation

@Observable
final class PutawayTasksViewModel {
    static let pageSize = 25
    static let taskTypePutaway = "putaway"

    private(set) var tasks: [PutawayTaskItem] = []
    private(set) var loadPhase: LoadPhase = .idle
    private(set) var dataMode: String?
    private(set) var isLoadingMore = false
    private(set) var canLoadMore = false

    var statusFilter: PutawayTaskStatusFilter = .all

    func setStatusFilter(_ filter: PutawayTaskStatusFilter) async {
        guard statusFilter != filter else { return }
        statusFilter = filter
        await refresh()
    }

    func applyStatusFilter(_ filter: PutawayTaskStatusFilter) async {
        await setStatusFilter(filter)
    }

    private var currentOffset = 0
    private var totalCount = 0

    private let environment: AppEnvironment
    private let inboundShipmentId: String?

    init(environment: AppEnvironment = .shared, inboundShipmentId: String? = nil) {
        self.environment = environment
        self.inboundShipmentId = inboundShipmentId
    }

    func refresh() async {
        currentOffset = 0
        totalCount = 0
        tasks = []
        canLoadMore = false
        await loadPage(reset: true)
    }

    func loadMore() async {
        guard canLoadMore, !isLoadingMore else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }
        await loadPage(reset: false)
    }

    private func loadPage(reset: Bool) async {
        if reset {
            loadPhase = .loading
        }

        let apiClient = environment.makeAPIClient()
        let orgId = environment.orgId

        if !(await apiClient.healthCheck()) {
            applyFoundationFallback(reset: reset)
            return
        }

        do {
            let response = try await apiClient.fetchTasks(
                orgId: orgId,
                taskType: Self.taskTypePutaway,
                status: statusFilter.apiStatus,
                inboundShipmentId: inboundShipmentId,
                limit: Self.pageSize,
                offset: currentOffset
            )
            dataMode = response.mode
            let mapped = response.items.map(PutawayAPIMapping.mapTask)

            if reset {
                tasks = mapped
            } else {
                tasks.append(contentsOf: mapped)
            }

            currentOffset = response.pagination.offset + mapped.count
            totalCount = response.pagination.total
            canLoadMore = currentOffset < totalCount

            if tasks.isEmpty {
                loadPhase = .empty(message: response.message ?? emptyMessage(for: response.mode))
            } else {
                loadPhase = .loaded
            }
        } catch {
            if reset, error.isDockWalkAPIHostUnreachable {
                applyFoundationFallback(reset: true)
                return
            }
            if reset {
                tasks = []
                loadPhase = .error(message: userFacingError(error))
            }
        }
    }

    private func applyFoundationFallback(reset: Bool) {
        let mapped = FoundationOperationalData.putawayTasks(
            filteredBy: inboundShipmentId,
            status: statusFilter
        )
        if reset {
            tasks = mapped
            currentOffset = mapped.count
            totalCount = mapped.count
            canLoadMore = false
            dataMode = "foundation"
            loadPhase = mapped.isEmpty
                ? .empty(message: emptyMessage(for: "foundation"))
                : .loaded
        }
    }

    private func emptyMessage(for mode: String) -> String {
        if inboundShipmentId != nil {
            return "No putaway tasks for this shipment."
        }
        if mode == "stub" {
            return "No putaway tasks in stub mode — configure Supabase on the API service."
        }
        if mode == "foundation" {
            return "No putaway tasks in offline preview data."
        }
        return "No putaway tasks for this organization."
    }

    private func userFacingError(_ error: Error) -> String {
        if let apiError = error as? APIClientError {
            return apiError.errorDescription ?? "Request failed."
        }
        return error.localizedDescription
    }
}
