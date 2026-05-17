import Foundation
import Observation

@Observable
final class ReceivingViewModel {
    let appointment: ReceivingAppointment

    private(set) var shipments: [InboundShipmentItem] = []
    private(set) var receivedLines: [ReceivedLine] = []
    private(set) var loadPhase: LoadPhase = .idle
    private(set) var dataMode: String?
    private(set) var isReceiving = false

    private let environment: AppEnvironment

    init(
        appointment: ReceivingAppointment,
        environment: AppEnvironment = .shared
    ) {
        self.appointment = appointment
        self.environment = environment
    }

    func load() async {
        loadPhase = .loading
        let apiClient = environment.makeAPIClient()

        do {
            let response: APIListResponse<InboundShipmentDTO> = try await apiClient.get(.inboundShipments)
            dataMode = response.mode

            let filtered = response.items
                .map(InboundAPIMapping.mapInboundShipment)
                .filter { $0.appointmentId == appointment.id }

            shipments = filtered
            receivedLines = filtered.map(InboundAPIMapping.mapShipmentToReceivedLine)

            if filtered.isEmpty {
                loadPhase = .empty(
                    message: response.message ?? emptyMessage(for: response.mode)
                )
            } else {
                loadPhase = .loaded
            }
        } catch {
            shipments = []
            receivedLines = []
            loadPhase = .error(message: userFacingError(error))
        }
    }

    func startReceiving() {
        isReceiving = true
    }

    func addSimulatedLine(from scan: ScanResult) {
        let line = ReceivedLine(
            id: UUID().uuidString,
            sku: scan.value,
            description: "Simulated scan (local)",
            quantity: 1
        )
        receivedLines.insert(line, at: 0)
    }

    private func emptyMessage(for mode: String) -> String {
        if mode == "stub" {
            return "No inbound shipments in stub mode for this appointment."
        }
        return "No inbound shipments linked to this appointment yet."
    }

    private func userFacingError(_ error: Error) -> String {
        if let apiError = error as? APIClientError {
            return apiError.errorDescription ?? "Request failed."
        }
        return error.localizedDescription
    }
}
