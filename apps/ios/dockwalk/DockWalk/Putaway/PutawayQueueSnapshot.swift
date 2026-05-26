import SwiftUI

/// Aggregate snapshot for pending UPC putaway cards.
struct PutawayQueueSnapshot: View {
    let cards: [PutawayUPCCard]
    let shipmentLabel: String?

    @State private var isExpanded = false

    private var totalQuantity: Double {
        cards.reduce(0) { $0 + $1.quantity }
    }

    private var uniqueLoads: Int {
        Set(cards.compactMap(\.inboundShipmentId)).count
    }

    private var lineAggregates: [PutawayQueueLineAggregate] {
        cards.map { card in
            PutawayQueueLineAggregate(
                upc: card.upc,
                skuSubtitle: card.secondarySKULabel,
                quantityLabel: card.quantityDisplay,
                routeLabel: card.routeLabel
            )
        }
    }

    var body: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Queue snapshot")
                        .font(DockWalkTheme.headlineFont)
                    Spacer()
                    if let shipmentLabel {
                        Text(shipmentLabel)
                            .font(.system(.caption2, design: .monospaced))
                            .foregroundStyle(DockWalkTheme.textSecondary)
                    }
                }

                HStack(spacing: 16) {
                    metric(label: "UPC", value: "\(cards.count)")
                    metric(label: "EA", value: formatQuantity(totalQuantity))
                    metric(label: "Loads", value: "\(max(uniqueLoads, cards.isEmpty ? 0 : 1))")
                    metric(label: "Cards", value: "\(cards.count)")
                }

                if !lineAggregates.isEmpty {
                    Divider()
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) { isExpanded.toggle() }
                    } label: {
                        HStack {
                            Label("UPC list", systemImage: isExpanded ? "chevron.up" : "chevron.down")
                                .font(DockWalkTheme.captionFont.weight(.semibold))
                            Spacer()
                        }
                        .foregroundStyle(DockWalkTheme.accent)
                    }
                    .buttonStyle(.plain)

                    if isExpanded {
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(lineAggregates) { line in
                                lineRow(line)
                            }
                        }
                        .padding(.top, 4)
                    }
                }
            }
        }
    }

    private func lineRow(_ line: PutawayQueueLineAggregate) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(line.upc)
                    .font(.system(.caption, design: .monospaced).weight(.semibold))
                Spacer()
                Text(line.quantityLabel)
                    .font(DockWalkTheme.captionFont)
                    .foregroundStyle(DockWalkTheme.textSecondary)
            }
            if let sku = line.skuSubtitle {
                Text(sku)
                    .font(DockWalkTheme.captionFont)
                    .foregroundStyle(DockWalkTheme.textSecondary)
            }
            Text(line.routeLabel)
                .font(DockWalkTheme.captionFont)
                .foregroundStyle(DockWalkTheme.textSecondary)
        }
        .padding(.vertical, 4)
    }

    private func metric(label: String, value: String) -> some View {
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
