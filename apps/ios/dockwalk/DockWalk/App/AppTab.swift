import Foundation

/// DockWalk by SkyView — primary tabs, in display order.
/// Today · Inbound · Inventory · Picking · Shipping
enum AppTab: Int, Hashable, CaseIterable {
    case today
    case inbound
    case inventory
    case picking
    case shipping
}
