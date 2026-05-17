import Foundation

enum AppointmentStatus: String, CaseIterable {
    case scheduled, checkedIn, receiving, complete, delayed

    var displayName: String {
        switch self {
        case .scheduled: return "Scheduled"
        case .checkedIn: return "Checked in"
        case .receiving: return "Receiving"
        case .complete: return "Complete"
        case .delayed: return "Delayed"
        }
    }

    var chipTone: StatusChip.Tone {
        switch self {
        case .scheduled: return .info
        case .checkedIn: return .neutral
        case .receiving: return .warning
        case .complete: return .success
        case .delayed: return .danger
        }
    }
}

struct ReceivingAppointment: Identifiable, Equatable {
    let id: String
    let carrier: String
    let dock: String
    let scheduledAt: Date
    let status: AppointmentStatus
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
    let status: String
    let expectedAt: Date?
    let receivedAt: Date?

    var statusDisplay: String {
        status.replacingOccurrences(of: "_", with: " ").capitalized
    }
}

struct InboundLineItem: Identifiable, Equatable {
    let id: String
    let sku: String
    let description: String
    let expectedQty: Double
    let receivedQty: Double
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
