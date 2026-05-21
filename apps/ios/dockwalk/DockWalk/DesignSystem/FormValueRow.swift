import SwiftUI

/// Form row with a persistent label on the left and value entry on the right.
struct FormValueRow: View {
    let label: String
    @Binding var text: String
    var placeholder: String = "—"
    var keyboardType: UIKeyboardType = .default
    var autocapitalization: TextInputAutocapitalization = .sentences

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(label)
                .font(DockWalkTheme.captionFont)
                .foregroundStyle(DockWalkTheme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            TextField(placeholder, text: $text)
                .multilineTextAlignment(.trailing)
                .textInputAutocapitalization(autocapitalization)
                .autocorrectionDisabled()
                .keyboardType(keyboardType)
                .font(DockWalkTheme.bodyFont)
                .frame(minWidth: 120)
        }
    }
}
