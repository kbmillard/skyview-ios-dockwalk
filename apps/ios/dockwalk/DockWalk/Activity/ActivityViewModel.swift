import Foundation
import Observation

@Observable
final class ActivityViewModel {
    static let pageSize = 25

    private(set) var events: [AuditEventItem] = []
    private(set) var loadPhase: LoadPhase = .idle
    private(set) var dataMode: String?
    private(set) var isLoadingMore = false
    private(set) var canLoadMore = false

    private var currentOffset = 0
    private var totalCount = 0

    private let environment: AppEnvironment

    init(environment: AppEnvironment = .shared) {
        self.environment = environment
    }

    func refresh() async {
        currentOffset = 0
        totalCount = 0
        events = []
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

        do {
            let response = try await apiClient.fetchAuditEvents(
                orgId: orgId,
                limit: Self.pageSize,
                offset: currentOffset
            )
            dataMode = response.mode
            let mapped = response.items.map(AuditAPIMapping.mapAuditEvent)

            if reset {
                events = mapped
            } else {
                events.append(contentsOf: mapped)
            }

            currentOffset = response.pagination.offset + mapped.count
            totalCount = response.pagination.total
            canLoadMore = currentOffset < totalCount

            if events.isEmpty {
                loadPhase = .empty(
                    message: response.message ?? emptyMessage(for: response.mode)
                )
            } else {
                loadPhase = .loaded
            }
        } catch {
            if reset {
                events = []
                loadPhase = .error(message: userFacingError(error))
            }
        }
    }

    private func emptyMessage(for mode: String) -> String {
        if mode == "stub" {
            return "No audit events in stub mode — configure Supabase on the API service."
        }
        return "No activity recorded for this organization yet."
    }

    private func userFacingError(_ error: Error) -> String {
        if let apiError = error as? APIClientError {
            return apiError.errorDescription ?? "Request failed."
        }
        return error.localizedDescription
    }
}
