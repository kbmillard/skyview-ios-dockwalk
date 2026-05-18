import SwiftUI

struct ScanResultCard: View {
    let result: ScanResult
    var onCopy: (() -> Void)?

    var body: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("Last scan")
                    .font(DockWalkTheme.captionFont)
                    .foregroundStyle(DockWalkTheme.textSecondary)
                Text(result.value)
                    .font(.system(.title3, design: .monospaced).weight(.semibold))
                    .textSelection(.enabled)
                HStack {
                    StatusChip(label: result.symbology, tone: .info)
                    Text(result.scannedAt.formatted(date: .omitted, time: .standard))
                        .font(DockWalkTheme.captionFont)
                        .foregroundStyle(DockWalkTheme.textSecondary)
                }
                if let onCopy {
                    Button {
                        onCopy()
                    } label: {
                        Label("Copy code", systemImage: "doc.on.doc")
                            .font(DockWalkTheme.captionFont)
                    }
                }
            }
        }
    }
}
