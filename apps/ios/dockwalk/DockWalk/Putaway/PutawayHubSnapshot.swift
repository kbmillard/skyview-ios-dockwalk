import SwiftUI

/// Single-task snapshot for the putaway hub (mirrors `ReceiveHubSnapshot`).
struct PutawayHubSnapshot: View {
    let task: PutawayTaskItem
    let savedStepCount: Int
    let totalSteps: Int

    var body: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Putaway snapshot")
                    .font(DockWalkTheme.headlineFont)

                HStack(spacing: 16) {
                    snapshotMetric(label: "Task", value: "1")
                    snapshotMetric(label: task.uom.uppercased(), value: formatQuantity(task.quantity))
                    snapshotMetric(label: "SKU", value: "1")
                    snapshotMetric(label: "Steps", value: "\(savedStepCount)/\(totalSteps)")
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
            Text(task.fromLocationCode.isEmpty ? "—" : task.fromLocationCode)
                .font(DockWalkTheme.bodyFont.weight(.semibold))
            Spacer()
            Image(systemName: "arrow.right")
                .font(.caption2)
                .foregroundStyle(DockWalkTheme.textSecondary)
            Spacer()
            Label("To", systemImage: "arrow.down.right.square")
                .font(DockWalkTheme.captionFont)
                .foregroundStyle(DockWalkTheme.textSecondary)
            Text(task.toLocationCode.isEmpty ? "—" : task.toLocationCode)
                .font(DockWalkTheme.bodyFont.weight(.semibold))
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
