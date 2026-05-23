import Foundation

/// How a scanner sheet applies a captured code.
enum ScannerApplyStyle {
    /// Last scan card + Use this code (receive, pick, putaway).
    case confirm
    /// Single-step Use this code from manual field or camera (inventory).
    case direct
}
