import Foundation
import Observation

enum ReceiveSubmitResult: Equatable {
    case success(duplicate: Bool, mode: String)
    case queuedOffline
    case failure(String)
}

@Observable
final class ShipmentDetailViewModel {
    let shipment: InboundShipmentItem
    let appointmentId: String?

    private(set) var lines: [InboundLineItem] = []
    private(set) var loadPhase: LoadPhase = .idle
    private(set) var dataMode: String?
    private(set) var isSubmitting = false
    private(set) var lastSubmitResult: ReceiveSubmitResult?

    private let environment: AppEnvironment
    private let syncStore: OfflineSyncStore

    init(
        shipment: InboundShipmentItem,
        appointmentId: String?,
        environment: AppEnvironment = .shared,
        syncStore: OfflineSyncStore = .shared
    ) {
        self.shipment = shipment
        self.appointmentId = appointmentId
        self.environment = environment
        self.syncStore = syncStore
    }

    func load() async {
        loadPhase = .loading
        let apiClient = environment.makeAPIClient()
        let orgId = environment.orgId

        do {
            let response: APIListResponse<InboundLineDTO> = try await apiClient.get(
                .inboundShipmentLines(shipmentId: shipment.id, orgId: orgId)
            )
            dataMode = response.mode
            lines = response.items.map(InboundAPIMapping.mapInboundLine)

            if lines.isEmpty {
                loadPhase = .empty(
                    message: response.message ?? emptyMessage(for: response.mode)
                )
            } else {
                loadPhase = .loaded
            }
        } catch {
            lines = []
            loadPhase = .error(message: userFacingError(error))
        }
    }

    func setReceiveAllRemaining() {
        for index in lines.indices {
            lines[index].receiveNow = lines[index].remainingQty
        }
    }

    func updateReceiveNow(lineId: String, quantity: Double) {
        guard let index = lines.firstIndex(where: { $0.id == lineId }) else { return }
        lines[index].receiveNow = max(0, quantity)
    }

    func submitReceive() async {
        let linesToReceive = lines.filter { $0.receiveNow > 0 }
        guard !linesToReceive.isEmpty else {
            lastSubmitResult = .failure("Enter a receive quantity for at least one line.")
            return
        }

        isSubmitting = true
        defer { isSubmitting = false }

        let request = ReceivingEventBuilder.buildRequest(
            environment: environment,
            appointmentId: appointmentId,
            shipmentId: shipment.id,
            lines: linesToReceive
        )

        guard request.lines.count >= 1 else {
            lastSubmitResult = .failure("No valid lines to receive.")
            return
        }

        let apiClient = environment.makeAPIClient()
        do {
            let response: ReceivingEventResponse = try await apiClient.post(
                .receivingEvents,
                body: request
            )
            lastSubmitResult = .success(
                duplicate: response.duplicate ?? false,
                mode: response.mode
            )
            await load()
        } catch {
            if APIClientErrorClassifier.shouldQueueOffline(for: error) {
                syncStore.enqueueReceivingEvent(
                    request,
                    summary: "Receive \(shipment.referenceNumber) — \(request.lines.count) line(s)"
                )
                lastSubmitResult = .queuedOffline
            } else {
                lastSubmitResult = .failure(userFacingError(error))
            }
        }
    }

    private func emptyMessage(for mode: String) -> String {
        if mode == "stub" {
            return "No lines in stub mode. Connect Supabase on the server or add lines via the API."
        }
        return "No inbound lines on this shipment yet."
    }

    private func userFacingError(_ error: Error) -> String {
        if let apiError = error as? APIClientError {
            return apiError.errorDescription ?? "Request failed."
        }
        return error.localizedDescription
    }
}
