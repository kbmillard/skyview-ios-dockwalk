import Foundation

enum TodayModels {

    struct LiveNowItem: Equatable {
        let loadId: String
        let title: String
        let subtitle: String
        let door: String
        let elapsedMinutes: Int?
    }

    struct OverviewStat: Identifiable, Equatable {
        let id: String
        let label: String
        let value: String
        let subvalue: String?
        let delta: String?
        let tone: StatTone

        enum StatTone {
            case ok, info, warn, crit
        }
    }

    struct QuickAction: Identifiable {
        let id: String
        let title: String
        let systemImage: String
        let tab: AppTab
    }

    struct RecentActivityItem: Identifiable, Equatable {
        let id: String
        let title: String
        let meta: String
        let barcode: String?
        let timeLabel: String
        let isLive: Bool
        let tone: FeedTone

        enum FeedTone {
            case ok, info, warn, muted, pending
        }
    }

    static let quickActions: [QuickAction] = [
        QuickAction(id: "receive", title: "Receive Load", systemImage: "arrow.down.to.line", tab: .inbound),
        QuickAction(id: "scan", title: "Scan Inventory", systemImage: "barcode.viewfinder", tab: .inventory),
        QuickAction(id: "putaway", title: "Start Putaway", systemImage: "arrow.down.to.line.compact", tab: .putaway),
        QuickAction(id: "ship", title: "Ship Order", systemImage: "arrow.up.to.line", tab: .shipping),
    ]
}
