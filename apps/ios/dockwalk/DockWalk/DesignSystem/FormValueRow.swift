import SwiftUI
import UIKit

/// Form row with a persistent label on the left and value entry on the right.
struct FormValueRow: View {
    let label: String
    @Binding var text: String
    var placeholder: String = ""
    var keyboardType: UIKeyboardType = .default
    var autocapitalizationType: UITextAutocapitalizationType = .sentences

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(label)
                .font(DockWalkTheme.captionFont)
                .foregroundStyle(DockWalkTheme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            CursorAtEndTextField(
                placeholder: placeholder,
                text: $text,
                keyboardType: keyboardType,
                autocapitalizationType: autocapitalizationType,
                textAlignment: .right
            )
            .frame(minWidth: 120)
        }
    }
}
