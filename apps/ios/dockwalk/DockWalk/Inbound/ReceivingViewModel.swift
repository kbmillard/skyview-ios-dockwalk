import Foundation
import Observation

@Observable
final class ReceivingViewModel {
    let appointment: ReceivingAppointment
    private(set) var receivedLines: [ReceivedLine] = []
    private(set) var isReceiving = false

    init(appointment: ReceivingAppointment) {
        self.appointment = appointment
        receivedLines = Self.stubLines
    }

    func startReceiving() {
        isReceiving = true
    }

    func addSimulatedLine(from scan: ScanResult) {
        let line = ReceivedLine(
            id: UUID().uuidString,
            sku: scan.value,
            description: "Scanned item (stub)",
            quantity: 1
        )
        receivedLines.insert(line, at: 0)
    }

    private static let stubLines: [ReceivedLine] = [
        ReceivedLine(id: "line-1", sku: "SKU-44102", description: "Shrink-wrapped cases", quantity: 48),
        ReceivedLine(id: "line-2", sku: "SKU-99201", description: "Floor-loaded drums", quantity: 12),
    ]
}
