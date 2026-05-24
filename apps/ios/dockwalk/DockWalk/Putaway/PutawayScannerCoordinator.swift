import Foundation
import Observation

/// Routes the global floating scan disc to the active putaway task hub.
@Observable
final class PutawayScannerCoordinator {
    static let shared = PutawayScannerCoordinator()

    private(set) var isPutawayHubActive = false
    private(set) var openScannerToken = 0
    private(set) var requestedStep: PutawayConfirmStep?

    func setPutawayHubActive(_ active: Bool) {
        isPutawayHubActive = active
        if !active {
            openScannerToken = 0
            requestedStep = nil
        }
    }

    func requestOpenScanner(step: PutawayConfirmStep? = nil) {
        guard isPutawayHubActive else { return }
        requestedStep = step
        openScannerToken += 1
    }
}
