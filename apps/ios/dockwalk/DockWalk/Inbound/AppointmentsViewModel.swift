import Foundation
import Observation

@Observable
final class AppointmentsViewModel {
    private(set) var appointments: [ReceivingAppointment] = []
    private(set) var loadPhase: LoadPhase = .idle
    private(set) var dataMode: String?
    private(set) var apiReachable = false

    private let environment: AppEnvironment

    init(environment: AppEnvironment = .shared) {
        self.environment = environment
    }

    func refresh(syncStore: OfflineSyncStore = .shared) async {
        loadPhase = .loading
        let apiClient = environment.makeAPIClient()
        let orgId = environment.orgId
        apiReachable = await apiClient.healthCheck()

        if FeatureFlags.foundationInboundDemoEnabled {
            applyFoundationDemoData()
            if apiReachable {
                await ReceivingEventReplayCoordinator.shared.attemptAutoReplayIfNeeded(
                    environment: environment,
                    syncStore: syncStore,
                    trigger: "receive_loaded"
                )
            }
            return
        }

        if !apiReachable {
            applyFoundationFallback()
            return
        }

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

            if apiReachable {
                await ReceivingEventReplayCoordinator.shared.attemptAutoReplayIfNeeded(
                    environment: environment,
                    syncStore: syncStore,
                    trigger: "receive_loaded"
                )
            }
        } catch {
            if error.isDockWalkAPIHostUnreachable {
                applyFoundationFallback()
                return
            }
            appointments = []
            loadPhase = .error(message: userFacingError(error))
        }
    }

    private func applyFoundationDemoData() {
        appointments = FoundationOperationalData.receivingAppointments
        dataMode = "foundation-demo"
        loadPhase = .loaded
    }

    private func applyFoundationFallback() {
        appointments = FoundationOperationalData.receivingAppointments
        dataMode = "foundation"
        apiReachable = false
        loadPhase = .loaded
    }

    private func emptyMessage(for mode: String) -> String {
        if mode == "stub" {
            return "DockWalk API is in stub mode — connect Supabase on the server to load appointments."
        }
        if mode == "foundation" {
            return "No appointments in offline preview data."
        }
        return "No appointments scheduled for this facility."
    }

    private func userFacingError(_ error: Error) -> String {
        if let apiError = error as? APIClientError {
            return apiError.errorDescription ?? "Request failed."
        }
        return error.localizedDescription
    }
    
    func createLoad(_ load: ReceivingAppointment) {
        appointments.insert(load, at: 0)
        if case .empty = loadPhase {
            loadPhase = .loaded
        }
    }

    func updateLoad(_ load: ReceivingAppointment) {
        guard let index = appointments.firstIndex(where: { $0.id == load.id }) else { return }
        appointments[index] = load
    }

    /// Door ids assigned to other loads (excludes `excludingLoadId` so the editor keeps its current door selectable).
    func occupiedDoorIds(excludingLoadId: String? = nil) -> Set<String> {
        Set(
            appointments
                .filter { $0.id != excludingLoadId }
                .compactMap(\.assignedDoorNumber)
        )
    }

    func doorPickerOptions(forLoadId loadId: String?, currentSelection: String?) -> [DockDoorPickerOption] {
        let occupied = occupiedDoorIds(excludingLoadId: loadId)
        return FoundationOperationalData.dockDoors.map { door in
            let doorId = door.doorNumber
            let isCurrent = currentSelection == doorId
            let isOccupied = occupied.contains(doorId) && !isCurrent
            return DockDoorPickerOption(
                id: doorId,
                label: doorId,
                statusLabel: isOccupied ? "In use" : (isCurrent ? "Selected" : "Open"),
                isAvailable: !isOccupied
            )
        }
    }
}
