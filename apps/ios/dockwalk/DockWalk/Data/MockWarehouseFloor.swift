import Foundation

/// Stable foundation mock data aligned with DockWalk floor prototype IDs.
enum MockWarehouseFloor {

    struct LiveNowItem: Equatable {
        let loadId: String
        let title: String
        let subtitle: String
        let door: String
        let elapsedMinutes: Int
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

    struct RecentWorkItem: Identifiable, Equatable {
        let id: String
        let title: String
        let meta: String
        let timeLabel: String
        let isLive: Bool
        let tone: FeedTone

        enum FeedTone {
            case ok, info, warn, muted
        }
    }

    struct DockDoorOption: Identifiable, Equatable {
        let id: String
        let label: String
        let status: String
        let isBusy: Bool
    }

    static let liveNow = LiveNowItem(
        loadId: "T-4471",
        title: "T-4471 receiving",
        subtitle: "Old Dominion · 22 pallets · 14 min elapsed",
        door: "Door 7",
        elapsedMinutes: 14
    )

    static let overviewStats: [OverviewStat] = [
        OverviewStat(id: "doors", label: "Active doors", value: "12", subvalue: "/14", delta: "↑ 2 vs yesterday", tone: .ok),
        OverviewStat(id: "inbound", label: "Inbound today", value: "8", subvalue: nil, delta: "3 remaining", tone: .info),
        OverviewStat(id: "pallets", label: "Verified pallets", value: "1,284", subvalue: nil, delta: "↑ 18% vs avg", tone: .ok),
        OverviewStat(id: "exceptions", label: "Exceptions", value: "3", subvalue: nil, delta: "2 awaiting review", tone: .crit),
    ]

    static let quickActions: [QuickAction] = [
        QuickAction(id: "receive", title: "Receive Load", systemImage: "arrow.down.to.line", tab: .receiving),
        QuickAction(id: "scan", title: "Scan Inventory", systemImage: "barcode.viewfinder", tab: .inventory),
        QuickAction(id: "putaway", title: "Start Putaway", systemImage: "arrow.left.arrow.right", tab: .putaway),
        QuickAction(id: "ship", title: "Ship Order", systemImage: "arrow.up.to.line", tab: .shipping),
    ]

    static let recentWork: [RecentWorkItem] = [
        RecentWorkItem(id: "rw1", title: "T-4468 received — 18 pallets", meta: "FedEx Freight · Door 4 · No exceptions", timeLabel: "8:42", isLive: false, tone: .ok),
        RecentWorkItem(id: "rw2", title: "T-4471 unloading at Door 7", meta: "Old Dominion · 14 of 22 pallets verified", timeLabel: "LIVE", isLive: true, tone: .info),
        RecentWorkItem(id: "rw3", title: "SKU BR-8821 moved to A-14", meta: "Brake Rotor Assembly · 36 ea · Putaway P-2038", timeLabel: "8:14", isLive: false, tone: .muted),
        RecentWorkItem(id: "rw4", title: "Shipment S-55120 staged", meta: "Midwest Supply · Door 2 · 14 items ready", timeLabel: "7:51", isLive: false, tone: .muted),
    ]

    static let dockDoors: [DockDoorOption] = [
        DockDoorOption(id: "D-01", label: "D-01", status: "In use", isBusy: true),
        DockDoorOption(id: "D-02", label: "D-02", status: "Open", isBusy: false),
        DockDoorOption(id: "D-03", label: "D-03", status: "Open", isBusy: false),
        DockDoorOption(id: "D-04", label: "D-04", status: "In use", isBusy: true),
        DockDoorOption(id: "D-05", label: "D-05", status: "In use", isBusy: true),
        DockDoorOption(id: "D-06", label: "D-06", status: "Loading", isBusy: true),
        DockDoorOption(id: "D-07", label: "D-07", status: "Recv'g", isBusy: true),
        DockDoorOption(id: "D-08", label: "D-08", status: "In use", isBusy: true),
        DockDoorOption(id: "D-09", label: "D-09", status: "Hold", isBusy: true),
        DockDoorOption(id: "D-10", label: "D-10", status: "Selected", isBusy: false),
        DockDoorOption(id: "D-11", label: "D-11", status: "In use", isBusy: true),
        DockDoorOption(id: "D-12", label: "D-12", status: "In use", isBusy: true),
        DockDoorOption(id: "D-13", label: "D-13", status: "Open", isBusy: false),
        DockDoorOption(id: "D-14", label: "D-14", status: "Maint", isBusy: false),
    ]

    static let scanConfirmSample = ScanConfirmPayload(
        itemName: "Pharma — Cold-chain Type B",
        sku: "8412",
        upc: "00854411",
        vendor: "Midwest Parts",
        destination: "C-08",
        confidence: 96,
        context: "Match found in 0.12s · pallet 14 of 22"
    )
}

struct ScanConfirmPayload: Equatable {
    let itemName: String
    let sku: String
    let upc: String
    let vendor: String
    let destination: String
    let confidence: Int
    let context: String
}
