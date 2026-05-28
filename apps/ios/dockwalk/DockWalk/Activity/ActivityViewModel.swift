import Foundation
import Observation

@Observable
final class ActivityViewModel {
    static let pageSize = 25

    private(set) var timeline: [ActivityTimelineEntry] = []
    private(set) var events: [AuditEventItem] = []
    private(set) var pendingEntries: [QueuedSyncAction] = []
    private(set) var loadPhase: LoadPhase = .idle
    private(set) var dataMode: String?
    private(set) var isLoadingMore = false
    private(set) var canLoadMore = false

    private var currentOffset = 0
    private var totalCount = 0

    private let environment: AppEnvironment
    private var syncStore: OfflineSyncStore?

    init(environment: AppEnvironment = .shared, syncStore: OfflineSyncStore? = nil) {
        self.environment = environment
        self.syncStore = syncStore
    }

    func bind(syncStore: OfflineSyncStore) {
        self.syncStore = syncStore
        rebuildTimeline()
    }

    func refresh() async {
        currentOffset = 0
        totalCount = 0
        events = []
        timeline = []
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
        let pending = syncStore?.queuedActions ?? []

        do {
            let response = try await apiClient.fetchAuditEvents(
                orgId: orgId,
                limit: Self.pageSize,
                offset: currentOffset
            )
            dataMode = response.mode
            let mapped = response.items.map { dto in
                let item = AuditAPIMapping.mapAuditEvent(dto)
                return ActivityFeedBuilder.enrichAuditEvent(item, pendingActions: pending)
            }

            if reset {
                events = mapped
            } else {
                events.append(contentsOf: mapped)
            }

            pendingEntries = pending
            rebuildTimeline()

            currentOffset = response.pagination.offset + mapped.count
            totalCount = response.pagination.total
            canLoadMore = currentOffset < totalCount

            if timeline.isEmpty {
                loadPhase = .empty(
                    message: response.message ?? emptyMessage(for: response.mode)
                )
            } else {
                loadPhase = .loaded
            }
        } catch {
            if reset {
                events = []
                pendingEntries = pending
                rebuildTimeline()
                loadPhase = .error(message: userFacingError(error))
            }
        }
    }

    private func rebuildTimeline() {
        timeline = ActivityFeedBuilder.buildTimeline(
            auditEvents: events,
            pendingActions: pendingEntries
        )
    }

    private func emptyMessage(for mode: String) -> String {
        if !pendingEntries.isEmpty {
            return "No server activity yet — see pending sync below."
        }
        if mode == "stub" {
            return "No activity recorded yet."
        }
        return "No activity recorded for this organization yet."
    }

    private func userFacingError(_ error: Error) -> String {
        if let apiError = error as? APIClientError {
            return apiError.errorDescription ?? "Could not load activity."
        }
        return "Can't reach DockWalk. Check connection in More."
    }
}
