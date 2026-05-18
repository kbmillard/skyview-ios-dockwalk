import Foundation

/// Primary dock workflow tabs (max 5 — Inventory reached from Today).
enum AppTab: Int, Hashable, CaseIterable {
    case today
    case receive
    case putaway
    case ship
    case more
}
