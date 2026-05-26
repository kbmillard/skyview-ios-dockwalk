import Foundation
import Observation

@Observable
final class PutawayTasksViewModel {
    static let pageSize = 25
    static let taskTypePutaway = "putaway"

    private(set) var cards: [PutawayUPCCard] = []
    private(set) var loadPhase: LoadPhase = .idle
    private(set) var dataMode: String?
    private(set) var isLoadingMore = false
    private(set) var canLoadMore = false

    /// Alias for views still named `tasks`.
    var tasks: [PutawayUPCCard] { cards }

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
    private var apiCards: [PutawayUPCCard] = []

    private let environment: AppEnvironment
    private let inboundShipmentId: String?
    private let inboundSession: InboundSessionStore
    private let completionStore: PutawayCompletionStore
    private let finalizedLoads: PutawayFinalizedLoadsStore

    init(
        environment: AppEnvironment = .shared,
        inboundShipmentId: String? = nil,
        inboundSession: InboundSessionStore = .shared,
        completionStore: PutawayCompletionStore = .shared,
        finalizedLoads: PutawayFinalizedLoadsStore = .shared
    ) {
        self.environment = environment
        self.inboundShipmentId = inboundShipmentId
        self.inboundSession = inboundSession
        self.completionStore = completionStore
        self.finalizedLoads = finalizedLoads
    }

    func refresh() async {
        currentOffset = 0
        apiCards = []
        cards = []
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

        let sessionCards = sessionPendingCards()
        var merged = sessionCards

        if FeatureFlags.foundationInboundDemoEnabled {
            applyDisplay(reset: reset, merged: mergeWithDemo(sessionCards: sessionCards), mode: "foundation-demo")
            return
        }

        let apiClient = environment.makeAPIClient()
        let orgId = environment.orgId

        if !(await apiClient.healthCheck()) {
            applyDisplay(
                reset: reset,
                merged: filterStatus(sessionCards),
                mode: "offline",
                emptyMessage: offlineEmptyMessage(sessionOnly: sessionCards.isEmpty)
            )
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
            let mapped = response.items.map(PutawayAPIMapping.mapCard)
            if reset {
                apiCards = mapped
            } else {
                apiCards.append(contentsOf: mapped)
            }
            currentOffset = response.pagination.offset + mapped.count
            canLoadMore = currentOffset < response.pagination.total
            merged = PutawayCardQueueBuilder.mergeAPI(apiCards, into: sessionCards, completionStore: completionStore)
            applyDisplay(reset: reset, merged: filterStatus(merged), mode: response.mode, emptyMessage: response.message)
        } catch {
            if reset, error.isDockWalkAPIHostUnreachable {
                applyDisplay(
                    reset: reset,
                    merged: filterStatus(sessionCards),
                    mode: "offline",
                    emptyMessage: offlineEmptyMessage(sessionOnly: sessionCards.isEmpty)
                )
                return
            }
            if reset {
                cards = filterStatus(sessionCards)
                loadPhase = .error(message: userFacingError(error))
            }
        }
    }

    private func sessionPendingCards() -> [PutawayUPCCard] {
        let _ = inboundSession.receivedInventoryRevision
        let _ = completionStore.revision
        let _ = finalizedLoads.revision

        let finalizedFilter: Set<String>? = inboundShipmentId == nil
            ? finalizedLoads.allFinalizedLoadIds()
            : nil

        return PutawayCardQueueBuilder.pendingCards(
            inboundShipmentId: inboundShipmentId,
            inboundSession: inboundSession,
            completionStore: completionStore,
            finalizedLoadIds: finalizedFilter
        )
    }

    private func mergeWithDemo(sessionCards: [PutawayUPCCard]) -> [PutawayUPCCard] {
        let seeds = FoundationOperationalData.putawayCards(
            filteredBy: inboundShipmentId,
            status: statusFilter
        )
        return PutawayCardQueueBuilder.mergeAPI(seeds, into: sessionCards, completionStore: completionStore)
    }

    private func offlineEmptyMessage(sessionOnly: Bool) -> String {
        if sessionOnly {
            return "Can't reach the DockWalk API. Receive on a load while offline, or reconnect to load tasks."
        }
        return "Can't reach the DockWalk API. Showing lines from this device session only."
    }

    private func filterStatus(_ list: [PutawayUPCCard]) -> [PutawayUPCCard] {
        guard let apiStatus = statusFilter.apiStatus else { return list }
        return list.filter { $0.status.rawValue == apiStatus }
    }

    private func applyDisplay(
        reset: Bool,
        merged: [PutawayUPCCard],
        mode: String,
        emptyMessage: String? = nil
    ) {
        guard reset else { return }
        cards = filterStatus(merged)
        canLoadMore = false
        dataMode = mode
        if cards.isEmpty {
            loadPhase = .empty(message: emptyMessage ?? defaultEmptyMessage(for: mode))
        } else {
            loadPhase = .loaded
        }
    }

    private func defaultEmptyMessage(for mode: String) -> String {
        if inboundShipmentId != nil {
            return "No UPC cards pending putaway for this shipment. Scan a UPC or receive inventory first."
        }
        if mode == "stub" {
            return "No putaway cards in stub mode — configure Supabase on the API service."
        }
        if mode == "foundation-demo" {
            return "Scan a UPC to put away, or receive on a load and finalize to build the queue."
        }
        if mode == "offline" {
            return "Can't reach the DockWalk API. Scan a UPC for session lines, or reconnect."
        }
        return "Scan a UPC to put away, or complete receiving on a load first."
    }

    private func userFacingError(_ error: Error) -> String {
        if let apiError = error as? APIClientError {
            return apiError.errorDescription ?? "Request failed."
        }
        return error.localizedDescription
    }
}
