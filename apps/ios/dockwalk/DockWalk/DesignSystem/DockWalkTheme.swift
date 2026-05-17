import SwiftUI

enum DockWalkTheme {
    static let screenPadding: CGFloat = 16
    static let sectionSpacing: CGFloat = 20
    static let cornerRadius: CGFloat = 14

    static let background = Color(.systemGroupedBackground)
    static let cardBackground = Color(.secondarySystemGroupedBackground)
    static let accent = Color(red: 0.12, green: 0.45, blue: 0.78)
    static let accentMuted = Color(red: 0.12, green: 0.45, blue: 0.78).opacity(0.12)
    static let textPrimary = Color.primary
    static let textSecondary = Color.secondary
    static let success = Color.green
    static let warning = Color.orange
    static let danger = Color.red

    static let titleFont = Font.system(.title2, design: .rounded).weight(.semibold)
    static let headlineFont = Font.system(.headline, design: .rounded).weight(.semibold)
    static let subtitleFont = Font.system(.subheadline, design: .default)
    static let bodyFont = Font.system(.body, design: .default)
    static let captionFont = Font.system(.caption, design: .default)
}
