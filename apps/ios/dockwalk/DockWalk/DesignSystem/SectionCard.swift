import SwiftUI

struct SectionCard<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(DockWalkTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: DockWalkTheme.cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DockWalkTheme.cornerRadius, style: .continuous)
                    .stroke(DockWalkTheme.cardBorder, lineWidth: 1)
            )
    }
}

#Preview {
    SectionCard {
        Text("Dock 3 · Carrier XYZ")
            .font(DockWalkTheme.bodyFont)
    }
    .padding()
    .background(DockWalkTheme.background)
}
