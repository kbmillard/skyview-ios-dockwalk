import SwiftUI

/// Aggregate snapshot for a list of putaway tasks (shipment-scoped queue or filtered list).
struct PutawayQueueSnapshot: View {
    let tasks: [PutawayTaskItem]
    let shipmentLabel: String?

    @State private var isExpanded = false

    private var totalQuantity: Double {
        tasks.reduce(0) { $0 + $1.quantity }
    }

    private var uniqueSKUs: Int {
        Set(tasks.map(\.sku)).count
    }

    private var uniqueBins: Int {
        Set(tasks.map(\.toLocationCode).filter { !$0.isEmpty }).count
    }

    private var groupedBySKU: [PutawayQueueGroupAggregate] {
        Dictionary(grouping: tasks, by: \.sku)
            .map { sku, items in
                PutawayQueueGroupAggregate(
                    sku: sku,
                    description: items.first?.description ?? "",
                    tasks: items
                )
            }
            .sorted { $0.sku < $1.sku }
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
                    metric(label: "Tasks", value: "\(tasks.count)")
                    metric(label: "Units", value: formatQuantity(totalQuantity))
                    metric(label: "SKU", value: "\(uniqueSKUs)")
                    metric(label: "Bins", value: "\(uniqueBins)")
                }

                if !groupedBySKU.isEmpty {
                    Divider()
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) { isExpanded.toggle() }
                    } label: {
                        HStack {
                            Label("SKU breakdown", systemImage: isExpanded ? "chevron.up" : "chevron.down")
                                .font(DockWalkTheme.captionFont.weight(.semibold))
                            Spacer()
                        }
                        .foregroundStyle(DockWalkTheme.accent)
                    }
                    .buttonStyle(.plain)

                    if isExpanded {
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(groupedBySKU) { group in
                                groupRow(group)
                            }
                        }
                        .padding(.top, 4)
                    }
                }
            }
        }
    }

    private func groupRow(_ group: PutawayQueueGroupAggregate) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(group.sku)
                    .font(DockWalkTheme.captionFont.weight(.semibold))
                Spacer()
                Text("\(formatQuantity(group.totalQuantity)) · \(group.tasks.count) task\(group.tasks.count == 1 ? "" : "s")")
                    .font(DockWalkTheme.captionFont)
                    .foregroundStyle(DockWalkTheme.textSecondary)
            }
            if !group.description.isEmpty {
                Text(group.description)
                    .font(DockWalkTheme.captionFont)
                    .foregroundStyle(DockWalkTheme.textSecondary)
                    .lineLimit(1)
            }
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
