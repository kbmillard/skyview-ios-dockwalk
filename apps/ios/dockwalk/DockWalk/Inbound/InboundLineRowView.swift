import SwiftUI

struct InboundLineRowView: View {
    let line: InboundLineItem
    let isReceiving: Bool
    let onReceiveOne: () -> Void

    var body: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(line.sku)
                            .font(.system(.title3, design: .monospaced).weight(.bold))
                        Text(line.description)
                            .font(DockWalkTheme.bodyFont)
                            .foregroundStyle(DockWalkTheme.textSecondary)
                    }
                    Spacer()
                    StatusChip(label: line.statusDisplay, tone: .neutral)
                }

                HStack(spacing: 16) {
                    qtyBlock(title: "Expected", value: line.expectedQty)
                    qtyBlock(title: "Received", value: line.receivedQty)
                    if line.quantityDamaged > 0 {
                        qtyBlock(title: "Damaged", value: line.quantityDamaged, tone: DockWalkTheme.danger)
                    }
                }

                PrimaryActionButton(
                    title: isReceiving ? "Receiving…" : "Receive 1",
                    systemImage: "barcode.viewfinder"
                ) {
                    onReceiveOne()
                }
                .disabled(isReceiving || line.remainingQty <= 0)
            }
        }
    }

    private func qtyBlock(title: String, value: Double, tone: Color? = nil) -> some View {
        let color = tone ?? DockWalkTheme.textSecondary
        return VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(DockWalkTheme.captionFont)
                .foregroundStyle(DockWalkTheme.textSecondary)
            Text(formatQty(value))
                .font(.system(.body, design: .rounded).weight(.semibold))
                .foregroundStyle(color)
        }
    }

    private func formatQty(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", value)
            : String(format: "%.2f", value)
    }
}
