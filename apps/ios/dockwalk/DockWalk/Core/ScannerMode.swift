import Foundation

/// Scanner scope contract for DockWalk floor work modes.
enum ScannerMode: Equatable {
    case globalInventory
    case load(loadId: String)
    case putawayTask(taskId: String)
    case shipment(shipmentId: String)

    var isGlobal: Bool {
        if case .globalInventory = self { return true }
        return false
    }

    /// Left label on the scanner chip (e.g. "Scanner locked to").
    var chipCaption: String {
        switch self {
        case .globalInventory:
            return "Scanner mode"
        case .load:
            return "Scanner locked to"
        case .putawayTask:
            return "Scanner locked to"
        case .shipment:
            return "Scanner locked to"
        }
    }

    /// Single-line label for receive load bar (work mode + lock target).
    var receiveLoadBarLabel: String? {
        guard case .load(let loadId) = self else { return nil }
        return "Receive load mode - Scanner locked to \(loadId)"
    }

    /// Right value on the scanner chip.
    var chipValue: String {
        switch self {
        case .globalInventory:
            return "Global lookup"
        case .load(let loadId):
            return loadId
        case .putawayTask(let taskId):
            return "Task \(taskId)"
        case .shipment(let shipmentId):
            return "Ship \(shipmentId)"
        }
    }
}
