import SwiftUI

/// Single-card snapshot for the putaway hub.
struct PutawayHubSnapshot: View {
    let card: PutawayUPCCard
    let savedStepCount: Int
    let totalSteps: Int

    var body: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Putaway snapshot")
                    .font(DockWalkTheme.headlineFont)

                HStack(spacing: 16) {
                    snapshotMetric(label: "UPC", value: "1")
                    snapshotMetric(label: card.uom.uppercased(), value: formatQuantity(card.quantity))
                    snapshotMetric(label: "From", value: card.fromLocationCode.isEmpty ? "—" : card.fromLocationCode)
                    snapshotMetric(label: "Steps", value: "\(savedStepCount)/\(totalSteps)")
                }

                Text(card.upc)
                    .font(.system(.body, design: .monospaced).weight(.semibold))
                    .foregroundStyle(DockWalkTheme.textPrimary)

                if let sku = card.secondarySKULabel {
                    Text(sku)
                        .font(DockWalkTheme.captionFont)
                        .foregroundStyle(DockWalkTheme.textSecondary)
                }

                Divider()

                routeRow
            }
        }
    }

    private var routeRow: some View {
        HStack(alignment: .center, spacing: 8) {
            Label("From", systemImage: "arrow.up.right.square")
                .font(DockWalkTheme.captionFont)
                .foregroundStyle(DockWalkTheme.textSecondary)
            Text(card.fromLocationCode.isEmpty ? "—" : card.fromLocationCode)
                .font(DockWalkTheme.bodyFont.weight(.semibold))
            Spacer()
            Image(systemName: "arrow.right")
                .font(.caption2)
                .foregroundStyle(DockWalkTheme.textSecondary)
            Spacer()
            Label("To", systemImage: "arrow.down.right.square")
                .font(DockWalkTheme.captionFont)
                .foregroundStyle(DockWalkTheme.textSecondary)
            Text(card.toLocationCode.isEmpty ? "scan bin" : card.toLocationCode)
                .font(DockWalkTheme.bodyFont.weight(.semibold))
                .foregroundStyle(card.toLocationCode.isEmpty ? DockWalkTheme.textSecondary : DockWalkTheme.textPrimary)
        }
    }

    private func snapshotMetric(label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(.title3, design: .rounded).weight(.bold))
                .foregroundStyle(DockWalkTheme.accent)
            Text(label)
                .font(DockWalkTheme.captionFont)
                .foregroundStyle(DockWalkTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func formatQuantity(_ value: Double) -> String {
        value == floor(value) ? String(Int(value)) : String(value)
    }
}
