import Foundation

/// DockWalk by SkyView — six primary tabs, in display order.
/// Today · Inbound · Inventory · Putaway · Picking · Shipping
enum AppTab: Int, Hashable, CaseIterable {
    case today
    case inbound
    case inventory
    case putaway
    case picking
    case shipping
}
