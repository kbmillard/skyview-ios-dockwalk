import Foundation
import Observation

@Observable
final class AppointmentsViewModel {
    private(set) var appointments: [ReceivingAppointment] = []
    private(set) var loadPhase: LoadPhase = .idle
    private(set) var dataMode: String?
    private(set) var apiReachable = false

    private let environment: AppEnvironment
    private let session: InboundSessionStore

    init(
        environment: AppEnvironment = .shared,
        session: InboundSessionStore = .shared
    ) {
        self.environment = environment
        self.session = session
    }

    func refresh(
        syncStore: OfflineSyncStore = .shared,
        forceReseedDemo: Bool = false
    ) async {
        if forceReseedDemo, FeatureFlags.foundationInboundDemoEnabled {
            session.resetDemoLoadsCache()
        }

        loadPhase = .loading
        let apiClient = environment.makeAPIClient()
        let orgId = environment.orgId
        apiReachable = await apiClient.healthCheck()

        if FeatureFlags.foundationInboundDemoEnabled {
            applyFoundationDemoData()
            #if DEBUG
            if apiReachable, SyncPreferencesStore.shared.receivingEventAutoReplayEnabled {
                await ReceivingEventReplayCoordinator.shared.attemptAutoReplayIfNeeded(
                    environment: environment,
                    syncStore: syncStore,
                    trigger: "receive_loaded"
                )
            }
            #endif
            return
        }

        if !apiReachable {
            applyAPIUnreachableFallback(syncStore: syncStore)
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

            #if DEBUG
            if apiReachable, SyncPreferencesStore.shared.receivingEventAutoReplayEnabled {
                await ReceivingEventReplayCoordinator.shared.attemptAutoReplayIfNeeded(
                    environment: environment,
                    syncStore: syncStore,
                    trigger: "receive_loaded"
                )
            }
            #endif
        } catch {
            if error.isDockWalkAPIHostUnreachable {
                applyAPIUnreachableFallback(syncStore: syncStore)
                return
            }
            appointments = []
            loadPhase = .error(message: userFacingError(error))
        }
    }

    private func applyFoundationDemoData() {
        appointments = session.seedDemoLoadsIfNeeded()
        dataMode = "foundation-demo"
        loadPhase = .loaded
    }

    private func applyAPIUnreachableFallback(syncStore: OfflineSyncStore) {
        apiReachable = false
        appointments = []
        dataMode = "offline"
        var message = "Can't reach the DockWalk API. Check More → API connection or try again."
        if syncStore.pendingSyncableCount > 0 {
            message += " \(syncStore.pendingSyncableCount) item(s) queued for sync."
        }
        loadPhase = .error(message: message)
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
        if FeatureFlags.foundationInboundDemoEnabled {
            session.insertLoad(load)
            appointments = session.seedDemoLoadsIfNeeded()
        } else {
            appointments.insert(load, at: 0)
        }
        if case .empty = loadPhase {
            loadPhase = .loaded
        }
    }

    func updateLoad(_ load: ReceivingAppointment) {
        if FeatureFlags.foundationInboundDemoEnabled {
            session.updateLoad(load)
            appointments = session.seedDemoLoadsIfNeeded()
        } else if let index = appointments.firstIndex(where: { $0.id == load.id }) {
            appointments[index] = load
        }
    }

    @discardableResult
    func syncLoadToAPI(
        _ load: ReceivingAppointment,
        syncStore: OfflineSyncStore = .shared
    ) async -> Bool {
        guard !FeatureFlags.foundationInboundDemoEnabled else { return true }
        let apiClient = environment.makeAPIClient()

        let payload = AppointmentUpdateRequest(
            referenceNumber: load.poNumber,
            scheduledAt: ISO8601DateFormatter().string(from: load.scheduledAt),
            status: load.status.rawValue,
            notes: nil,
            metadata: [
                "carrier_name": load.carrier,
                "door_number": load.assignedDoorNumber ?? "",
                "pallet_count": String(load.palletCount),
                "vendor_name": load.vendor ?? "",
                "expected_line_count": String(load.expectedLineCount),
                "received_line_count": String(load.receivedLineCount),
            ]
        )

        func queueUpdate() {
            syncStore.enqueueAppointmentUpdate(
                appointmentId: load.id,
                orgId: environment.orgId,
                payload: payload,
                summary: "Update inbound load \(load.poNumber)"
            )
        }

        guard await apiClient.healthCheck() else {
            queueUpdate()
            return false
        }

        do {
            _ = try await apiClient.updateAppointment(
                id: load.id,
                orgId: environment.orgId,
                body: payload
            )
            return true
        } catch {
            if APIClientErrorClassifier.shouldQueueOffline(for: error) {
                queueUpdate()
            }
            return false
        }
    }

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
