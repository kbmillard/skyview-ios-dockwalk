import SwiftUI

struct DebugPanelView: View {
    @Environment(AppEnvironment.self) private var environment
    @Environment(OfflineSyncStore.self) private var syncStore
    @Environment(ReceivingEventReplayCoordinator.self) private var replayCoordinator

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
                            if action.receivingEventPayload != nil {
                                Text("Receiving event payload stored")
                                    .font(DockWalkTheme.captionFont)
                                    .foregroundStyle(DockWalkTheme.warning)
                            }
                            if let payload = action.taskActionPayload {
                                Text("Task action: \(payload.action) · \(payload.taskId)")
                                    .font(.system(.caption2, design: .monospaced))
                                    .foregroundStyle(DockWalkTheme.textSecondary)
                            }
                            if let lastError = action.lastError {
                                Text(lastError)
                                    .font(DockWalkTheme.captionFont)
                                    .foregroundStyle(DockWalkTheme.danger)
                            }
                        }
                    }
                }

                if FeatureFlags.syncBatchReplayEnabled {
                    Text("Replay path: POST /api/sync/events (batch)")
                        .font(DockWalkTheme.captionFont)
                        .foregroundStyle(DockWalkTheme.textSecondary)
                }

                if syncStore.pendingSyncableCount > 0 {
                    Button(replayCoordinator.isReplaying ? "Replaying…" : "Replay offline queue") {
                        Task {
                            await replayCoordinator.replayReceivingEvents(
                                environment: environment,
                                syncStore: syncStore,
                                label: "Manual"
                            )
                        }
                    }
                    .disabled(replayCoordinator.isReplaying)
                }

                if let message = syncStore.lastReplayMessage {
                    Text(message)
                        .font(DockWalkTheme.captionFont)
                        .foregroundStyle(DockWalkTheme.textSecondary)
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
            .environment(SyncPreferencesStore.shared)
            .environment(ReceivingEventReplayCoordinator.shared)
    }
}
