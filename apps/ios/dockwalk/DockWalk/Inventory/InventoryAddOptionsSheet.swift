import SwiftUI

/// Sheet that presents options for adding inventory: scan or manual entry.
struct InventoryAddOptionsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(ScannerPreferencesStore.self) private var scannerPreferences
    
    let onScanSelected: () -> Void
    let onManualAddSelected: () -> Void
    
    var body: some View {
        NavigationStack {
            VStack(spacing: Tokens.Space.lg) {
                Text("Add Inventory")
                    .font(Tokens.Font.titleSection)
                    .kerning(Tokens.Tracking.titleSection)
                    .foregroundStyle(Tokens.Color.Ink.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, Tokens.Space.base)
                
                // Scan option
                optionCard(
                    title: "Scan Barcode",
                    subtitle: "Use camera to scan item barcode or QR code",
                    systemImage: "barcode.viewfinder",
                    isEnabled: scannerPreferences.isScannerActive
                ) {
                    dismiss()
                    onScanSelected()
                }
                
                // Manual add option
                optionCard(
                    title: "Manual Entry",
                    subtitle: "Enter inventory details manually",
                    systemImage: "keyboard",
                    isEnabled: true
                ) {
                    dismiss()
                    onManualAddSelected()
                }
                
                Spacer()
            }
            .padding(DockWalkTheme.screenPadding)
            .background(DockWalkTheme.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
    
    private func optionCard(
        title: String,
        subtitle: String,
        systemImage: String,
        isEnabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            Haptics.scanSuccess()
            action()
        } label: {
            HStack(spacing: Tokens.Space.base) {
                // Icon container
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Tokens.Color.Accent.horizonSoft)
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: systemImage)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(Tokens.Color.Accent.horizon)
                }
                
                // Text content
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(Tokens.Font.titleCard)
                        .kerning(Tokens.Tracking.titleCard)
                        .foregroundStyle(Tokens.Color.Ink.primary)
                    
                    Text(subtitle)
                        .font(Tokens.Font.bodySecondary)
                        .foregroundStyle(Tokens.Color.Ink.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Tokens.Color.Ink.tertiary)
            }
            .padding(Tokens.Space.base)
            .background(Tokens.Color.Surface.card)
            .clipShape(RoundedRectangle(cornerRadius: Tokens.Radius.card, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Tokens.Radius.card, style: .continuous)
                    .stroke(Tokens.Color.Divider.hairline, lineWidth: 0.5)
            )
        }
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1.0 : 0.5)
        .buttonStyle(.plain)
    }
}

#Preview {
    InventoryAddOptionsSheet(
        onScanSelected: {},
        onManualAddSelected: {}
    )
    .environment(ScannerPreferencesStore.shared)
}
