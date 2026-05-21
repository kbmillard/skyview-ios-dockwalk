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

// MARK: - WorkflowStatus Conformance
extension InboundLoadStatus: WorkflowStatus {
    var id: String { rawValue }
    
    var sortOrder: Int {
        switch self {
        case .scheduled: return 0
        case .checkedIn: return 1
        case .staged: return 2
        case .receiving: return 3
        case .complete: return 4
        case .cancelled: return 5
        }
    }
}

// MARK: - Stage Filter
enum InboundStageFilter: String, CaseIterable, Identifiable {
    case scheduled
    case checkedIn
    case staged
    case receiving
    case complete
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .scheduled: return "Scheduled"
        case .checkedIn: return "Checked In"
        case .staged: return "Staged"
        case .receiving: return "Receiving"
        case .complete: return "Complete"
        }
    }
    
    var status: InboundLoadStatus {
        switch self {
        case .scheduled: return .scheduled
        case .checkedIn: return .checkedIn
        case .staged: return .staged
        case .receiving: return .receiving
        case .complete: return .complete
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
    let vendor: String?
    let expectedLineCount: Int
    let receivedLineCount: Int
    let doorNumber: String?
}

extension ReceivingAppointment {
    /// Human-readable dock assignment for list/detail UI.
    var doorAssignmentLabel: String {
        if let doorNumber, !doorNumber.isEmpty {
            return doorNumber
        }
        let trimmed = dock.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty || trimmed == "—" {
            return "Not assigned"
        }
        if Self.looksLikePlaceholderDockID(trimmed) {
            return "Not assigned"
        }
        return trimmed
    }

    private static func looksLikePlaceholderDockID(_ value: String) -> Bool {
        guard value.lowercased().hasPrefix("dock ") else { return false }
        let suffix = value.dropFirst(5).replacingOccurrences(of: "-", with: "")
        guard suffix.count >= 8 else { return false }
        return suffix.allSatisfy(\.isHexDigit)
    }

    /// Canonical door id (e.g. D-25) when this load holds a door; nil if unassigned.
    var assignedDoorNumber: String? {
        if let doorNumber, !doorNumber.isEmpty { return doorNumber }
        let trimmed = dock.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, trimmed != "—", !Self.looksLikePlaceholderDockID(trimmed) else {
            return nil
        }
        return trimmed
    }
}

struct DockDoorPickerOption: Identifiable, Equatable {
    let id: String
    let label: String
    let statusLabel: String
    let isAvailable: Bool
}

/// In-progress inventory captured during receive work mode (local until synced).
struct ReceiveInventoryDraft: Identifiable, Equatable {
    let id: String
    var sku: String
    var partNumber: String
    var itemName: String
    var quantity: String
    var location: String
    var isSaved: Bool = false

    static func empty() -> ReceiveInventoryDraft {
        ReceiveInventoryDraft(
            id: UUID().uuidString,
            sku: "",
            partNumber: "",
            itemName: "",
            quantity: "",
            location: "RECV-STAGE"
        )
    }

    static func fromScan(_ code: String) -> ReceiveInventoryDraft {
        var draft = empty()
        draft.sku = code
        draft.itemName = "Scanned item"
        draft.quantity = "1"
        return draft
    }
}

struct ReceivedLine: Identifiable, Equatable {
    let id: String
    let sku: String
    let description: String
    let quantity: Int
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
