import SwiftUI

/// Visible scanner state chip — matches HTML prototype scanchip styling.
struct ScannerLockChip: View {
    let mode: ScannerMode

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: mode.isGlobal ? "magnifyingglass" : "lock.fill")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(mode.isGlobal ? DockWalkTheme.textSecondary : Color(red: 0.18, green: 0.44, blue: 0.90))

            if let receiveLabel = mode.receiveLoadBarLabel {
                Text(receiveLabel)
                    .font(.system(size: 10.5, design: .monospaced).weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            } else {
                Text(mode.chipCaption)
                    .font(.system(size: 10.5, design: .monospaced))
                    .foregroundStyle(mode.isGlobal ? DockWalkTheme.textSecondary : Color(white: 0.66))

                Spacer(minLength: 4)

                Text(mode.chipValue)
                    .font(.system(size: 10.5, design: .monospaced).weight(.semibold))
                    .foregroundStyle(mode.isGlobal ? DockWalkTheme.textPrimary : .white)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(mode.isGlobal ? DockWalkTheme.cardBackground : Color(red: 0.04, green: 0.08, blue: 0.16))
                .overlay {
                    if mode.isGlobal {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(DockWalkTheme.background, lineWidth: 1)
                    }
                }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(mode.receiveLoadBarLabel ?? "\(mode.chipCaption) \(mode.chipValue)")
    }
}

#Preview {
    VStack(spacing: 12) {
        ScannerLockChip(mode: .globalInventory)
        ScannerLockChip(mode: .load(loadId: "T-4471"))
        ScannerLockChip(mode: .putawayTask(taskId: "P-2041"))
        ScannerLockChip(mode: .shipment(shipmentId: "S-55120"))
    }
    .padding()
    .background(DockWalkTheme.background)
}
