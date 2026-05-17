import Foundation
import Observation

@Observable
final class PutawayTaskDetailViewModel {
    private(set) var task: PutawayTaskItem?
    private(set) var loadPhase: LoadPhase = .idle
    private(set) var dataMode: String?

    private let taskId: String
    private let environment: AppEnvironment

    init(taskId: String, initialTask: PutawayTaskItem? = nil, environment: AppEnvironment = .shared) {
        self.taskId = taskId
        self.task = initialTask
        self.environment = environment
        if initialTask != nil {
            loadPhase = .loaded
        }
    }

    func load() async {
        if task == nil {
            loadPhase = .loading
        }

        let apiClient = environment.makeAPIClient()

        do {
            let response = try await apiClient.fetchTask(id: taskId, orgId: environment.orgId)
            dataMode = response.mode
            task = WarehouseTaskAPIMapping.mapTask(response.item)
            loadPhase = .loaded
        } catch {
            if task == nil {
                loadPhase = .error(message: userFacingError(error))
            }
        }
    }

    private func userFacingError(_ error: Error) -> String {
        if let apiError = error as? APIClientError {
            return apiError.errorDescription ?? "Request failed."
        }
        return error.localizedDescription
    }
}
