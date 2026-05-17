import SwiftUI

struct DebugPanelView: View {
    @Environment(AppEnvironment.self) private var environment
    @Environment(OfflineSyncStore.self) private var syncStore
    @State private var healthResult: String = "—"

    var body: some View {
        List {
            Section("Environment") {
                LabeledContent("API", value: environment.apiBaseURL.absoluteString)
                LabeledContent("Facility", value: environment.facilityId)
                LabeledContent("Org", value: environment.orgId)
            }

            Section("API probe") {
                Text(healthResult)
                    .font(.system(.body, design: .monospaced))
                Button("Ping /health") {
                    Task {
                        let client = APIClient(baseURL: environment.apiBaseURL)
                        let ok = await client.healthCheck()
                        healthResult = ok ? "OK" : "Unavailable (expected if API not running)"
                    }
                }
            }

            Section("Sync queue") {
                if syncStore.queuedActions.isEmpty {
                    Text("Queue empty")
                } else {
                    ForEach(syncStore.queuedActions) { action in
                        VStack(alignment: .leading) {
                            Text(action.summary)
                            Text(action.kind)
                                .font(DockWalkTheme.captionFont)
                                .foregroundStyle(DockWalkTheme.textSecondary)
                        }
                    }
                }
                Button("Clear queue", role: .destructive) {
                    syncStore.clearQueue()
                }
            }
        }
        .navigationTitle("Debug")
    }
}

#Preview {
    NavigationStack {
        DebugPanelView()
            .environment(AppEnvironment.shared)
            .environment(OfflineSyncStore.shared)
    }
}
