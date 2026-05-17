import Foundation

enum OutboundOrderStatus: String {
    case staged, picking, loading, readyToClose

    var displayName: String {
        switch self {
        case .staged: return "Staged"
        case .picking: return "Picking"
        case .loading: return "Loading"
        case .readyToClose: return "Ready to close"
        }
    }

    var chipTone: StatusChip.Tone {
        switch self {
        case .staged: return .neutral
        case .picking: return .info
        case .loading: return .warning
        case .readyToClose: return .success
        }
    }
}

struct OutboundOrder: Identifiable, Equatable {
    let id: String
    let customer: String
    let door: String
    let status: OutboundOrderStatus
    let cartonCount: Int
}
