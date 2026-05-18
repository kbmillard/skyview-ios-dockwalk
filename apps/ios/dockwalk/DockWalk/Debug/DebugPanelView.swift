import SwiftUI

struct DebugPanelView: View {
    @Environment(AppEnvironment.self) private var environment
    @Environment(OfflineSyncStore.self) private var syncStore
    @Environment(ScannerPreferencesStore.self) private var scannerPreferences
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

            if !FeatureFlags.liveScannerEnabled {
                Section {
                    Toggle("Enable scanner on this device", isOn: internalScannerBinding)
                } header: {
                    Text("Scanner (internal QA)")
                } footer: {
                    Text(
                        "Shows Scanner Lab and scan buttons on this device only. Turn off here (or More → Turn off scanner) and leave Scanner Lab — scan UI closes automatically. Not the same as Auto-replay under Sync."
                    )
                    .font(DockWalkTheme.captionFont)
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

    private var internalScannerBinding: Binding<Bool> {
        Binding(
            get: { scannerPreferences.internalScannerEnabled },
            set: { scannerPreferences.setInternalScannerEnabled($0) }
        )
    }
}

#Preview {
    NavigationStack {
        DebugPanelView()
            .environment(AppEnvironment.shared)
            .environment(OfflineSyncStore.shared)
            .environment(SyncPreferencesStore.shared)
            .environment(ScannerPreferencesStore.shared)
            .environment(ReceivingEventReplayCoordinator.shared)
    }
}
