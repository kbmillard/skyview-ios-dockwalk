import Foundation

/// Dock door status for WMS operations
struct DockDoorStatus: Identifiable, Equatable {
    let id: String
    let doorNumber: String
    let status: DoorStatus
    let assignedLoad: String?
    
    enum DoorStatus: String {
        case open
        case occupied
        
        var displayName: String {
            switch self {
            case .open: return "Open"
            case .occupied: return "Occupied"
            }
        }
        
        var chipTone: StatusChip.Tone {
            switch self {
            case .open: return .success
            case .occupied: return .warning
            }
        }
    }
}

/// Inbound load grouped by workflow status
struct InboundLoadGroup: Identifiable {
    let id = UUID()
    let status: InboundLoadStatus
    let count: Int
    let loads: [InboundLoad]
}

/// Individual inbound load
struct InboundLoad: Identifiable, Equatable {
    let id: String
    let referenceNumber: String
    let carrier: String?
    let status: InboundLoadStatus
    let scheduledAt: Date?
    let doorAssignment: String?
}

// NOTE: Putaway models moved to /Putaway/PutawayModels.swift
// PutawayQueueGroup and PutawayTaskStatus now live in the Putaway module
