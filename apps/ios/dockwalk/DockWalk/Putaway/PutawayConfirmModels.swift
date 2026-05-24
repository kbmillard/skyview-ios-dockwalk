import Foundation

/// Single confirmation step on a putaway task hub (mirrors `ReceiveInventoryDraft.isSaved` lifecycle).
enum PutawayConfirmStep: String, CaseIterable, Codable, Identifiable {
    case fromLocation
    case sku
    case toLocation
    case quantity

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .fromLocation: return "From location"
        case .sku: return "SKU"
        case .toLocation: return "To location"
        case .quantity: return "Quantity"
        }
    }

    var scanTitle: String {
        switch self {
        case .fromLocation: return "Scan from location"
        case .sku: return "Scan SKU"
        case .toLocation: return "Scan to location"
        case .quantity: return "Confirm quantity"
        }
    }

    var systemImage: String {
        switch self {
        case .fromLocation: return "arrow.up.right.square"
        case .sku: return "shippingbox"
        case .toLocation: return "arrow.down.right.square"
        case .quantity: return "number"
        }
    }
}

/// Local capture for a single putaway confirmation step on a task.
struct PutawayConfirmDraft: Identifiable, Equatable {
    let id: String
    var taskId: String
    var step: PutawayConfirmStep
    var scannedValue: String
    var confirmedQty: Double?
    var isSaved: Bool

    static func empty(taskId: String, step: PutawayConfirmStep) -> PutawayConfirmDraft {
        PutawayConfirmDraft(
            id: UUID().uuidString,
            taskId: taskId,
            step: step,
            scannedValue: "",
            confirmedQty: nil,
            isSaved: false
        )
    }

    static func fromScan(taskId: String, step: PutawayConfirmStep, value: String) -> PutawayConfirmDraft {
        PutawayConfirmDraft(
            id: UUID().uuidString,
            taskId: taskId,
            step: step,
            scannedValue: value,
            confirmedQty: nil,
            isSaved: false
        )
    }
}

/// Aggregate for the putaway-tasks list snapshot.
struct PutawayQueueGroupAggregate: Identifiable, Equatable {
    var id: String { sku }
    let sku: String
    let description: String
    let tasks: [PutawayTaskItem]

    var totalQuantity: Double {
        tasks.reduce(0) { $0 + $1.quantity }
    }
}
