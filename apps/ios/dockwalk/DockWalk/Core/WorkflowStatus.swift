import Foundation

/// Protocol that all workflow status enums must conform to
/// Enables registry-based access for future customer customization
protocol WorkflowStatus {
    /// API slug (matches backend Zod schema string literal)
    var id: String { get }
    
    /// Human-readable display name for UI
    var displayName: String { get }
    
    /// Status chip visual style
    var chipTone: StatusChip.Tone { get }
    
    /// SF Symbol icon name
    var systemImage: String { get }
    
    /// Sort order for UI lists (0 = first)
    var sortOrder: Int { get }
}

/// Workflow type identifier
enum WorkflowType: String, CaseIterable {
    case inbound = "inbound"
    case putaway = "putaway"
    case picking = "picking"
    case outbound = "outbound"
    case inventory = "inventory"
}

/// Registry protocol for workflow status lookup
/// Enables future migration from hardcoded enums to API-driven custom schemas
protocol StatusRegistry {
    /// Returns all available statuses for a workflow type
    func statuses(for workflow: WorkflowType) -> [WorkflowStatus]
    
    /// Looks up a specific status by API slug
    func status(for workflow: WorkflowType, id: String) -> WorkflowStatus?
    
    /// Returns the default/initial status for a workflow
    func defaultStatus(for workflow: WorkflowType) -> WorkflowStatus
}

/// Default registry that returns hardcoded enum values
/// Later: swap to APIStatusRegistry that loads from backend + caches offline
class DefaultStatusRegistry: StatusRegistry {
    static let shared = DefaultStatusRegistry()
    
    private init() {}
    
    func statuses(for workflow: WorkflowType) -> [WorkflowStatus] {
        switch workflow {
        case .inbound:
            return InboundLoadStatus.allCases.sorted { $0.sortOrder < $1.sortOrder }
        case .putaway:
            return PutawayTaskStatus.allCases.sorted { $0.sortOrder < $1.sortOrder }
        case .picking:
            return PickTaskStatus.allCases.sorted { $0.sortOrder < $1.sortOrder }
        case .outbound:
            return OutboundOrderStatus.allCases.sorted { $0.sortOrder < $1.sortOrder }
        case .inventory:
            return InventoryStatus.allCases.sorted { $0.sortOrder < $1.sortOrder }
        }
    }
    
    func status(for workflow: WorkflowType, id: String) -> WorkflowStatus? {
        statuses(for: workflow).first { $0.id == id }
    }
    
    func defaultStatus(for workflow: WorkflowType) -> WorkflowStatus {
        switch workflow {
        case .inbound:
            return InboundLoadStatus.scheduled
        case .putaway:
            return PutawayTaskStatus.pending
        case .picking:
            return PickTaskStatus.readyToPick
        case .outbound:
            return OutboundOrderStatus.readyToPick
        case .inventory:
            return InventoryStatus.available
        }
    }
}
