import SwiftUI
import UIKit

/// Text field that places the caret at the end when editing begins — easier to clear prefilled values.
struct CursorAtEndTextField: UIViewRepresentable {
    let placeholder: String
    @Binding var text: String
    var isFocused: Binding<Bool>? = nil
    var keyboardType: UIKeyboardType = .default
    var autocapitalizationType: UITextAutocapitalizationType = .sentences
    var textAlignment: NSTextAlignment = .right

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, isFocused: isFocused)
    }

    func makeUIView(context: Context) -> UITextField {
        let field = UITextField()
        field.delegate = context.coordinator
        field.placeholder = placeholder
        field.font = UIFont.preferredFont(forTextStyle: .body)
        field.keyboardType = keyboardType
        field.autocapitalizationType = autocapitalizationType
        field.autocorrectionType = .no
        field.textAlignment = textAlignment
        field.addTarget(
            context.coordinator,
            action: #selector(Coordinator.textChanged(_:)),
            for: .editingChanged
        )
        return field
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }
        if uiView.isFirstResponder {
            Coordinator.moveCursorToEndAsync(in: uiView)
        }
    }

    final class Coordinator: NSObject, UITextFieldDelegate {
        @Binding var text: String
        var isFocused: Binding<Bool>?

        init(text: Binding<String>, isFocused: Binding<Bool>?) {
            _text = text
            self.isFocused = isFocused
        }

        @objc func textChanged(_ sender: UITextField) {
            text = sender.text ?? ""
        }

        func textFieldDidBeginEditing(_ textField: UITextField) {
            isFocused?.wrappedValue = true
            Self.moveCursorToEnd(in: textField)
            Self.moveCursorToEndAsync(in: textField)
        }

        func textFieldDidEndEditing(_ textField: UITextField) {
            isFocused?.wrappedValue = false
        }

        static func moveCursorToEnd(in textField: UITextField) {
            let end = textField.endOfDocument
            textField.selectedTextRange = textField.textRange(from: end, to: end)
        }

        static func moveCursorToEndAsync(in textField: UITextField) {
            DispatchQueue.main.async {
                guard textField.isFirstResponder else { return }
                moveCursorToEnd(in: textField)
            }
        }
    }
}
