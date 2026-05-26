import Foundation

/// Single confirmation step on a putaway card hub.
enum PutawayConfirmStep: String, CaseIterable, Codable, Identifiable {
    case upc
    case fromLocation
    case toLocation
    case quantity

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .upc: return "UPC"
        case .fromLocation: return "From location"
        case .toLocation: return "To location"
        case .quantity: return "Quantity"
        }
    }

    var scanTitle: String {
        switch self {
        case .upc: return "Scan UPC"
        case .fromLocation: return "Scan from location"
        case .toLocation: return "Scan to bin"
        case .quantity: return "Confirm quantity"
        }
    }

    var systemImage: String {
        switch self {
        case .upc: return "barcode.viewfinder"
        case .fromLocation: return "arrow.up.right.square"
        case .toLocation: return "arrow.down.right.square"
        case .quantity: return "number"
        }
    }
}

/// Local capture for a single putaway confirmation step on a card.
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

/// One UPC line in the putaway queue snapshot breakdown.
struct PutawayQueueLineAggregate: Identifiable, Equatable {
    var id: String { upc }
    let upc: String
    let skuSubtitle: String?
    let quantityLabel: String
    let routeLabel: String
}
