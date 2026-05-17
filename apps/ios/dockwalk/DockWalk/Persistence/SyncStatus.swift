import Foundation

enum SyncStatus: Equatable {
    case online
    case offline
    case syncing
    case pending(count: Int)
    case failed(message: String)

    var label: String {
        switch self {
        case .online: return "Connected — changes sync automatically"
        case .offline: return "Offline — actions queue locally"
        case .syncing: return "Syncing queued actions…"
        case .pending(let count): return "\(count) action\(count == 1 ? "" : "s") waiting to sync"
        case .failed(let message): return message
        }
    }

    var chipLabel: String {
        switch self {
        case .online: return "Online"
        case .offline: return "Offline"
        case .syncing: return "Syncing"
        case .pending(let count): return "Pending \(count)"
        case .failed: return "Failed"
        }
    }

    var chipTone: StatusChip.Tone {
        switch self {
        case .online: return .success
        case .offline: return .warning
        case .syncing: return .info
        case .pending: return .info
        case .failed: return .danger
        }
    }
}
