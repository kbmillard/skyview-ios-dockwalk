import Foundation
import Observation

@Observable
final class AppointmentsViewModel {
    private(set) var appointments: [ReceivingAppointment] = []
    private(set) var loadPhase: LoadPhase = .idle
    private(set) var dataMode: String?
    private(set) var apiReachable = false

    private let apiClient: APIClient
    private let orgId: String

    init(
        apiClient: APIClient = APIClient(baseURL: AppEnvironment.shared.apiBaseURL),
        orgId: String = AppEnvironment.shared.orgId
    ) {
        self.apiClient = apiClient
        self.orgId = orgId
    }

    func refresh() async {
        loadPhase = .loading
        apiReachable = await apiClient.healthCheck()

        do {
            let response: APIListResponse<AppointmentDTO> = try await apiClient.get(
                .appointments(orgId: orgId)
            )
            dataMode = response.mode
            let mapped = response.items.map(InboundAPIMapping.mapAppointment)

            if mapped.isEmpty {
                appointments = []
                loadPhase = .empty(
                    message: response.message ?? emptyMessage(for: response.mode)
                )
            } else {
                appointments = mapped
                loadPhase = .loaded
            }
        } catch {
            appointments = []
            loadPhase = .error(message: userFacingError(error))
        }
    }

    private func emptyMessage(for mode: String) -> String {
        if mode == "stub" {
            return "DockWalk API is in stub mode — connect Supabase on the server to load appointments."
        }
        return "No appointments scheduled for this facility."
    }

    private func userFacingError(_ error: Error) -> String {
        if let apiError = error as? APIClientError {
            return apiError.errorDescription ?? "Request failed."
        }
        return error.localizedDescription
    }
}
