import Foundation
import Observation

/// Routes the global floating scan disc to the active receive-load screen.
@Observable
final class ReceiveScannerCoordinator {
    static let shared = ReceiveScannerCoordinator()

    private(set) var isReceiveHubActive = false
    private(set) var openScannerToken = 0

    func setReceiveHubActive(_ active: Bool) {
        isReceiveHubActive = active
        if !active { openScannerToken = 0 }
    }

    func requestOpenScanner() {
        guard isReceiveHubActive else { return }
        openScannerToken += 1
    }
}
