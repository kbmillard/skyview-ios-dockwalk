import Foundation
import Observation

@Observable
final class TodayDashboardViewModel {
    private(set) var appointmentCount: Int?
    private(set) var putawayTaskCount: Int?
    private(set) var inventoryItemCount: Int?
    private(set) var loadPhase: LoadPhase = .idle

    private let environment: AppEnvironment

    init(environment: AppEnvironment = .shared) {
        self.environment = environment
    }

    func refresh() async {
        loadPhase = .loading
        let apiClient = environment.makeAPIClient()
        let orgId = environment.orgId

        do {
            async let appointmentsResponse: APIListResponse<AppointmentDTO> = apiClient.get(
                .appointments(orgId: orgId)
            )
            async let tasksResponse = apiClient.fetchTasks(
                orgId: orgId,
                taskType: PutawayTasksViewModel.taskTypePutaway,
                status: nil,
                inboundShipmentId: nil,
                limit: 1,
                offset: 0
            )
            
            let appointments = try await appointmentsResponse
            let tasks = try await tasksResponse

            appointmentCount = appointments.items.count
            putawayTaskCount = tasks.pagination.total
            
            inventoryItemCount = nil
            
            loadPhase = .loaded
        } catch {
            appointmentCount = nil
            putawayTaskCount = nil
            inventoryItemCount = nil
            loadPhase = .error(message: userFacingError(error))
        }
    }

    private func userFacingError(_ error: Error) -> String {
        if let apiError = error as? APIClientError {
            return apiError.errorDescription ?? "Could not load dashboard."
        }
        return error.localizedDescription
    }
}
