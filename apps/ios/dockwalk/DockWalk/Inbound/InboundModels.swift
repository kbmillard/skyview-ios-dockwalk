import Foundation

/// Unified inbound load/shipment/appointment status
/// rawValue matches API slug contract
enum InboundLoadStatus: String, CaseIterable, Codable {
    case scheduled = "scheduled"
    case checkedIn = "arrived"
    case staged = "staged"
    case receiving = "receiving"
    case complete = "completed"
    case cancelled = "cancelled"

    var displayName: String {
        switch self {
        case .scheduled: return "Scheduled"
        case .checkedIn: return "Checked in"
        case .staged: return "Staged"
        case .receiving: return "Receiving"
        case .complete: return "Complete"
        case .cancelled: return "Cancelled"
        }
    }

    var chipTone: StatusChip.Tone {
        switch self {
        case .scheduled: return .info
        case .checkedIn: return .neutral
        case .staged: return .neutral
        case .receiving: return .warning
        case .complete: return .success
        case .cancelled: return .danger
        }
    }
    
    var systemImage: String {
        switch self {
        case .scheduled: return "calendar"
        case .checkedIn: return "checkmark.circle"
        case .staged: return "door.left.hand.open"
        case .receiving: return "arrow.down.doc"
        case .complete: return "checkmark.seal.fill"
        case .cancelled: return "xmark.circle"
        }
    }
}

struct ReceivingAppointment: Identifiable, Equatable {
    let id: String
    let carrier: String
    let dock: String
    let scheduledAt: Date
    let status: InboundLoadStatus
    let poNumber: String
    let palletCount: Int
}

struct ReceivedLine: Identifiable, Equatable {
    let id: String
    let sku: String
    let description: String
    let quantity: Int
}

struct InboundShipmentItem: Identifiable, Equatable {
    let id: String
    let appointmentId: String?
    let referenceNumber: String
    let status: InboundLoadStatus
    let expectedAt: Date?
    let receivedAt: Date?
}

struct InboundLineItem: Identifiable, Equatable {
    let id: String
    let sku: String
    let description: String
    let expectedQty: Double
    let receivedQty: Double
    let quantityDamaged: Double
    var receiveNow: Double
    let uom: String
    let status: String

    var statusDisplay: String {
        status.replacingOccurrences(of: "_", with: " ").capitalized
    }

    var remainingQty: Double {
        max(0, expectedQty - receivedQty)
    }
}
