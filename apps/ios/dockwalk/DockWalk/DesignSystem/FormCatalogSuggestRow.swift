import SwiftUI

/// Typeahead row against the inventory catalog (SKU or part description).
struct FormCatalogSuggestRow: View {
    enum FieldKind {
        case sku
        case partDescription
    }

    let label: String
    let kind: FieldKind
    @Binding var text: String
    var placeholder: String = ""
    let suggestions: [InventoryItem]
    let onSelect: (InventoryItem) -> Void

    @State private var isFocused = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(label)
                    .font(DockWalkTheme.captionFont)
                    .foregroundStyle(DockWalkTheme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                CursorAtEndTextField(
                    placeholder: placeholder,
                    text: $text,
                    isFocused: $isFocused,
                    autocapitalizationType: .allCharacters,
                    textAlignment: .right
                )
                .frame(minWidth: 120)
            }

            if isFocused, !suggestions.isEmpty {
                VStack(spacing: 0) {
                    ForEach(suggestions) { item in
                        Button {
                            onSelect(item)
                            isFocused = false
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(suggestionTitle(for: item))
                                        .font(DockWalkTheme.bodyFont.weight(.semibold))
                                        .foregroundStyle(DockWalkTheme.textPrimary)
                                    Text(suggestionSubtitle(for: item))
                                        .font(DockWalkTheme.captionFont)
                                        .foregroundStyle(DockWalkTheme.textSecondary)
                                }
                                Spacer()
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal, 12)
                        }
                        .buttonStyle(.plain)
                        if item.id != suggestions.last?.id {
                            Divider()
                        }
                    }
                }
                .background(DockWalkTheme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(DockWalkTheme.textSecondary.opacity(0.2), lineWidth: 1)
                )
            }
        }
    }

    private func suggestionTitle(for item: InventoryItem) -> String {
        switch kind {
        case .sku:
            return item.sku
        case .partDescription:
            return item.partDescription ?? item.sku
        }
    }

    private func suggestionSubtitle(for item: InventoryItem) -> String {
        item.itemName
    }
}
