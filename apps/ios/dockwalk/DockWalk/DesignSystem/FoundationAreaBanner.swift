import SwiftUI

/// Explains placeholder / foundation-preview areas (Ship, Inventory).
struct FoundationAreaBanner: View {
    let title: String
    let detail: String

    var body: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "hammer.fill")
                        .foregroundStyle(DockWalkTheme.accent)
                    Text(title)
                        .font(DockWalkTheme.headlineFont)
                }
                Text(detail)
                    .font(DockWalkTheme.bodyFont)
                    .foregroundStyle(DockWalkTheme.textSecondary)
            }
        }
    }
}
