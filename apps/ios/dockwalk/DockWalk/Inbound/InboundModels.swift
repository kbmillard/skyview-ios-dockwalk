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
    var upc: String
    var sku: String
    var partDescription: String
    var itemName: String
    /// Number of cases (boxes/packages).
    var casesQty: String
    /// Eaches per case when cases are set; total eaches when cases are empty.
    var eachesQty: String
    var location: String
    var quantity: String
    var status: InventoryStatus
    var isSaved: Bool = false
    var isCommittedToCatalog: Bool = false

    var parsedCases: Int? {
        let value = Int(casesQty.trimmingCharacters(in: .whitespaces)) ?? 0
        return value > 0 ? value : nil
    }

    var parsedEaches: Int? {
        let value = Int(eachesQty.trimmingCharacters(in: .whitespaces)) ?? 0
        return value > 0 ? value : nil
    }

    /// Total pieces: cases × eaches per case, or whichever single field is set.
    var totalEaches: Int? {
        switch (parsedCases, parsedEaches) {
        case let (cases?, eachesPerCase?):
            return cases * eachesPerCase
        case let (cases?, nil):
            return cases
        case let (nil, eaches?):
            return eaches
        case (nil, nil):
            return nil
        }
    }

    var quantityDisplay: String {
        if parsedCases != nil || parsedEaches != nil {
            switch (parsedCases, parsedEaches, totalEaches) {
            case let (cases?, eachesPerCase?, total?):
                return "\(cases) CS × \(eachesPerCase) = \(total) EA"
            case let (cases?, nil, _):
                return "\(cases) CS"
            case let (nil, eaches?, _):
                return "\(eaches) EA"
            default:
                return "—"
            }
        }
        if let qty = parsedQuantity {
            return "\(qty) ea"
        }
        return "—"
    }

    /// Compact qty for SKU list UPC sub-rows.
    var upcLineQuantityLabel: String {
        quantityDisplay
    }

    var hasIdentifier: Bool {
        !sku.trimmingCharacters(in: .whitespaces).isEmpty
            || !upc.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var hasQuantityInput: Bool {
        parsedQuantity != nil || parsedCases != nil || parsedEaches != nil
    }

    var parsedQuantity: Int? {
        let value = Int(quantity.trimmingCharacters(in: .whitespaces)) ?? 0
        return value > 0 ? value : nil
    }

    /// Quantity used for hub totals and catalog commit.
    var committedQuantity: Int {
        if parsedCases != nil || parsedEaches != nil {
            return totalEaches ?? 0
        }
        return parsedQuantity ?? 0
    }

    func makeInventoryItem() -> InventoryItem? {
        let qty = committedQuantity
        guard qty > 0 else { return nil }
        let trimmedSKU = sku.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedUPC = upc.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedName = itemName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedLocation = location.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedSKU.isEmpty || !trimmedUPC.isEmpty else { return nil }
        guard !trimmedName.isEmpty, !trimmedLocation.isEmpty else { return nil }

        let trimmedPart = partDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedSKU = trimmedSKU.isEmpty ? trimmedUPC : trimmedSKU
        return InventoryItem(
            id: id,
            sku: resolvedSKU,
            upc: trimmedUPC.isEmpty ? nil : trimmedUPC,
            partDescription: trimmedPart.isEmpty ? nil : trimmedPart,
            itemName: trimmedName,
            description: trimmedName,
            quantity: qty,
            location: trimmedLocation,
            status: status,
            onHand: qty,
            reserved: 0
        )
    }

    static func empty() -> ReceiveInventoryDraft {
        ReceiveInventoryDraft(
            id: UUID().uuidString,
            upc: "",
            sku: "",
            partDescription: "",
            itemName: "",
            casesQty: "",
            eachesQty: "",
            location: "RECV-STAGE",
            quantity: "",
            status: .available
        )
    }

    static func fromScan(_ upcCode: String) -> ReceiveInventoryDraft {
        var draft = empty()
        draft.upc = upcCode
        return draft
    }

    /// New UPC line for an existing SKU — copies metadata, clears qty fields.
    static func cloningSKU(from template: ReceiveInventoryDraft, upc: String) -> ReceiveInventoryDraft {
        ReceiveInventoryDraft(
            id: UUID().uuidString,
            upc: upc,
            sku: template.sku,
            partDescription: template.partDescription,
            itemName: template.itemName,
            casesQty: "",
            eachesQty: "",
            location: template.location,
            quantity: "",
            status: template.status
        )
    }
}

/// Hub SKU list row with nested UPC lines from saved receive drafts.
struct ReceiveSKUGroup: Identifiable, Equatable {
    var id: String { sku }
    let sku: String
    let name: String
    let description: String
    let upcLines: [ReceiveUPCLine]
}

struct ReceiveUPCLine: Identifiable, Equatable {
    let id: String
    let upc: String
    let quantityLabel: String
    let location: String
    let status: InventoryStatus
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
