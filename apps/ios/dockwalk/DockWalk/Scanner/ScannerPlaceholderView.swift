import SwiftUI

struct ScannerPlaceholderView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var lastResult: ScanResult?

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Scanner stub")
                    .font(DockWalkTheme.captionFont)
                    .foregroundStyle(DockWalkTheme.textSecondary)

                ZStack {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(style: StrokeStyle(lineWidth: 3, dash: [10, 8]))
                        .foregroundStyle(DockWalkTheme.accent.opacity(0.5))
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(DockWalkTheme.accent, lineWidth: 2)
                        .frame(width: 220, height: 120)
                    Image(systemName: "barcode.viewfinder")
                        .font(.system(size: 48))
                        .foregroundStyle(DockWalkTheme.accent)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 280)
                .background(Color.black.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: DockWalkTheme.cornerRadius))

                if FeatureFlags.liveScannerEnabled {
                    Text("Live scanner would appear here.")
                        .font(DockWalkTheme.bodyFont)
                } else {
                    Text("AVFoundation scanner not enabled in this build.")
                        .font(DockWalkTheme.bodyFont)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(DockWalkTheme.textSecondary)
                }

                PrimaryActionButton(title: "Simulate Scan", systemImage: "wand.and.stars") {
                    lastResult = ScanResult(value: "SKU-DEMO-\(Int.random(in: 1000...9999))")
                }

                if let lastResult {
                    SectionCard {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Last scan")
                                .font(DockWalkTheme.captionFont)
                                .foregroundStyle(DockWalkTheme.textSecondary)
                            Text(lastResult.value)
                                .font(.system(.title3, design: .monospaced).weight(.semibold))
                            Text(lastResult.symbology)
                                .font(DockWalkTheme.captionFont)
                                .foregroundStyle(DockWalkTheme.textSecondary)
                        }
                    }
                }

                Spacer()
            }
            .padding(DockWalkTheme.screenPadding)
            .navigationTitle("Scan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    ScannerPlaceholderView()
}
