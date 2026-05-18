import SwiftUI

extension View {
    /// Dismisses a scanner sheet when the runtime / compile-time gate turns off.
    func dismissScannerSheetWhenInactive(
        _ scannerPreferences: ScannerPreferencesStore,
        isPresented: Binding<Bool>
    ) -> some View {
        onChange(of: scannerPreferences.revision) { _, _ in
            if !scannerPreferences.isScannerActive {
                isPresented.wrappedValue = false
            }
        }
    }

    /// Pops or dismisses this screen if scanner access is revoked while visible.
    func exitIfScannerInactive(_ scannerPreferences: ScannerPreferencesStore) -> some View {
        modifier(ScannerInactiveExitModifier(scannerPreferences: scannerPreferences))
    }
}

private struct ScannerInactiveExitModifier: ViewModifier {
    @Environment(\.dismiss) private var dismiss
    let scannerPreferences: ScannerPreferencesStore

    func body(content: Content) -> some View {
        content
            .onChange(of: scannerPreferences.revision) { _, _ in
                if !scannerPreferences.isScannerActive {
                    dismiss()
                }
            }
    }
}
