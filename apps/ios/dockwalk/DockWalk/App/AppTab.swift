import Foundation

/// DockWalk by SkyView — five primary tabs, in display order.
/// Inventory is intentionally the center tab (the universal lookup hub).
enum AppTab: Int, Hashable, CaseIterable {
    case today
    case receiving
    case inventory
    case putaway
    case shipping
}
