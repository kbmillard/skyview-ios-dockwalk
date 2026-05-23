import SwiftUI

struct ReceiveHubSnapshot: View {
    let totalUPCs: Int
    let totalCases: Int
    let totalEaches: Int
    let uniqueSKUs: Int
    let skuGroups: [ReceiveSKUGroup]
    var onAddAnotherUPC: ((String) -> Void)?

    @State private var isListExpanded = false
    @State private var expandedSKUs: Set<String> = []

    var body: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Load Snapshot")
                    .font(DockWalkTheme.headlineFont)

                HStack(spacing: 16) {
                    snapshotMetric(label: "UPC", value: "\(totalUPCs)")
                    snapshotMetric(label: "CS", value: "\(totalCases)")
                    snapshotMetric(label: "EA", value: "\(totalEaches)")
                    snapshotMetric(label: "SKU", value: "\(uniqueSKUs)")
                }

                if !skuGroups.isEmpty {
                    Divider()

                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            isListExpanded.toggle()
                        }
                    } label: {
                        HStack {
                            Label("SKU List", systemImage: isListExpanded ? "chevron.up" : "chevron.down")
                                .font(DockWalkTheme.captionFont.weight(.semibold))
                            Spacer()
                        }
                        .foregroundStyle(DockWalkTheme.accent)
                    }

                    if isListExpanded {
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(skuGroups) { group in
                                skuGroupRow(group)
                                if group.sku != skuGroups.last?.sku {
                                    Divider()
                                        .padding(.vertical, 4)
                                }
                            }
                        }
                        .padding(.top, 4)
                    }
                }
            }
        }
    }

    private func skuGroupRow(_ group: ReceiveSKUGroup) -> some View {
        let isSKUExpanded = expandedSKUs.contains(group.sku)
        return VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 8) {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        if isSKUExpanded {
                            expandedSKUs.remove(group.sku)
                        } else {
                            expandedSKUs.insert(group.sku)
                        }
                    }
                } label: {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: isSKUExpanded ? "chevron.down" : "chevron.right")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(DockWalkTheme.accent)
                            .padding(.top, 2)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(group.sku)
                                .font(DockWalkTheme.captionFont.weight(.semibold))
                                .foregroundStyle(DockWalkTheme.textPrimary)

                            if !group.name.isEmpty {
                                Text(group.name)
                                    .font(DockWalkTheme.captionFont)
                                    .foregroundStyle(DockWalkTheme.textSecondary)
                            }

                            if !group.description.isEmpty {
                                Text(group.description)
                                    .font(DockWalkTheme.captionFont)
                                    .foregroundStyle(DockWalkTheme.textSecondary)
                            }
                        }
                        Spacer(minLength: 0)
                    }
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 6)
            .contentShape(Rectangle())
            .onLongPressGesture(minimumDuration: 0.5) {
                onAddAnotherUPC?(group.sku)
            }

            if isSKUExpanded {
                VStack(alignment: .leading, spacing: 0) {
                    upcTableHeader
                    ForEach(group.upcLines) { line in
                        upcTableRow(line)
                    }
                }
                .padding(.leading, 20)
                .padding(.bottom, 8)
            }
        }
    }

    private var upcTableHeader: some View {
        HStack(spacing: 8) {
            Text("UPC")
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("Qty")
                .frame(width: 88, alignment: .trailing)
            Text("Loc")
                .frame(width: 72, alignment: .leading)
            Text("Status")
                .frame(width: 64, alignment: .trailing)
        }
        .font(DockWalkTheme.captionFont.weight(.semibold))
        .foregroundStyle(DockWalkTheme.textSecondary)
        .padding(.vertical, 4)
    }

    private func upcTableRow(_ line: ReceiveUPCLine) -> some View {
        HStack(spacing: 8) {
            Text(line.upc)
                .font(DockWalkTheme.captionFont)
                .foregroundStyle(DockWalkTheme.textPrimary)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(line.quantityLabel)
                .font(DockWalkTheme.captionFont)
                .foregroundStyle(DockWalkTheme.textSecondary)
                .lineLimit(2)
                .multilineTextAlignment(.trailing)
                .frame(width: 88, alignment: .trailing)

            Text(line.location)
                .font(DockWalkTheme.captionFont)
                .foregroundStyle(DockWalkTheme.textSecondary)
                .lineLimit(1)
                .frame(width: 72, alignment: .leading)

            Text(line.status.displayName)
                .font(DockWalkTheme.captionFont)
                .foregroundStyle(DockWalkTheme.textSecondary)
                .lineLimit(1)
                .frame(width: 64, alignment: .trailing)
        }
        .padding(.vertical, 6)
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
}

#Preview {
    ReceiveHubSnapshot(
        totalUPCs: 5,
        totalCases: 12,
        totalEaches: 144,
        uniqueSKUs: 3,
        skuGroups: [
            ReceiveSKUGroup(
                sku: "SKU-001",
                name: "Widget A",
                description: "Blue widget",
                upcLines: [
                    ReceiveUPCLine(
                        id: "1",
                        upc: "11111",
                        quantityLabel: "10 CS × 5 = 50 EA",
                        location: "RECV-STAGE",
                        status: .available
                    )
                ]
            )
        ]
    )
    .padding()
}
