import SwiftUI

struct InspectionStubView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DockWalkTheme.sectionSpacing) {
                SectionCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Camera evidence — stubbed", systemImage: "camera.fill")
                            .font(DockWalkTheme.headlineFont)
                        Text("DockWalk will capture trailer and product evidence on the dock. AI-assisted damage review is intentionally disabled in this foundation build.")
                            .font(DockWalkTheme.bodyFont)
                            .foregroundStyle(DockWalkTheme.textSecondary)
                        if FeatureFlags.aiInspectionEnabled {
                            StatusChip(label: "AI enabled", tone: .info)
                        } else {
                            StatusChip(label: "AI off", tone: .neutral)
                        }
                    }
                }
                PrimaryActionButton(title: "Open placeholder camera", systemImage: "camera", style: .secondary) {}
                Text("No AVFoundation session, Gemini calls, or SiteWalk imports in this repo.")
                    .font(DockWalkTheme.captionFont)
                    .foregroundStyle(DockWalkTheme.textSecondary)
            }
            .padding(DockWalkTheme.screenPadding)
        }
        .background(DockWalkTheme.background)
        .navigationTitle("Inspection")
    }
}

#Preview {
    NavigationStack {
        InspectionStubView()
    }
}
