import SwiftUI

struct DebugPanelView: View {
    @Environment(AppEnvironment.self) private var environment
    @Environment(OfflineSyncStore.self) private var syncStore

    var body: some View {
        List {
            Section("Environment") {
                LabeledContent("API", value: environment.apiBaseURL.absoluteString)
                LabeledContent("Facility", value: environment.facilityId)
                LabeledContent("Org", value: environment.orgId)
                LabeledContent("Config revision", value: "\(environment.configRevision)")
            }

            Section {
                NavigationLink("API connection & health test") {
                    APIConnectionSettingsView()
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
