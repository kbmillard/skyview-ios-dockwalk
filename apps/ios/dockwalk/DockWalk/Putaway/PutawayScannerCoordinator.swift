import Foundation
import Observation

/// Routes the global floating scan disc to the active putaway task hub or putaway tab.
@Observable
final class PutawayScannerCoordinator {
    static let shared = PutawayScannerCoordinator()

    private(set) var isPutawayHubActive = false
    private(set) var isPutawayTabActive = false
    private(set) var openScannerToken = 0
    private(set) var requestedStep: PutawayConfirmStep?

    func setPutawayHubActive(_ active: Bool) {
        isPutawayHubActive = active
        if !active {
            requestedStep = nil
        }
    }

    func setPutawayTabActive(_ active: Bool) {
        isPutawayTabActive = active
    }

    func requestOpenScanner(step: PutawayConfirmStep? = nil) {
        guard isPutawayHubActive || isPutawayTabActive else { return }
        requestedStep = step
        openScannerToken += 1
    }
}
