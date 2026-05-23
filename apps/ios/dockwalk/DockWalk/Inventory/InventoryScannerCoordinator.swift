import Foundation
import Observation

/// Requests opening the Inventory tab scanner from the global floating scan disc.
@Observable
final class InventoryScannerCoordinator {
    static let shared = InventoryScannerCoordinator()

    private(set) var openScannerToken = 0

    func requestOpenScanner() {
        openScannerToken += 1
    }
}
