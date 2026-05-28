import SwiftUI

/// Worker-facing offline queue: UPC-first rows, replay, and status — not admin Settings.
struct SyncQueueView: View {
    @Environment(AppEnvironment.self) private var environment
    @Environment(OfflineSyncStore.self) private var syncStore
    @Environment(SyncPreferencesStore.self) private var syncPreferences
    @Environment(ReceivingEventReplayCoordinator.self) private var replayCoordinator

    var body: some View {
        List {
            Section {
                HStack {
                    Text("Status")
                    Spacer()
                    StatusChip(label: syncStore.status.chipLabel, tone: syncStore.status.chipTone)
                }
                if syncStore.pendingSyncableCount > 0 {
                    LabeledContent("Pending", value: "\(syncStore.pendingSyncableCount)")
                } else {
                    Text("All caught up — nothing waiting to send.")
                        .font(DockWalkTheme.captionFont)
                        .foregroundStyle(DockWalkTheme.textSecondary)
                }
            }

            if FeatureFlags.isReceivingEventAutoReplayPermitted {
                Section {
                    Toggle("Auto-replay when online", isOn: autoReplayBinding)
                } footer: {
                    Text("Sends queued work automatically after the app sees a healthy connection.")
                        .font(DockWalkTheme.captionFont)
                }
            }

            Section("Queued actions") {
                if syncStore.queuedActions.isEmpty {
                    Text("No queued actions")
                        .foregroundStyle(DockWalkTheme.textSecondary)
                } else {
                    ForEach(syncStore.queuedActions) { action in
                        queueRow(action)
                    }
                }
            }

            if syncStore.pendingSyncableCount > 0 {
                Section {
                    Button {
                        Task {
                            await replayCoordinator.replayReceivingEvents(
                                environment: environment,
                                syncStore: syncStore,
                                label: "Manual"
                            )
                        }
                    } label: {
                        HStack {
                            Spacer()
                            if replayCoordinator.isReplaying {
                                ProgressView()
                                Text("Replaying…")
                            } else {
                                Text("Replay now")
                                    .fontWeight(.semibold)
                            }
                            Spacer()
                        }
                    }
                    .disabled(replayCoordinator.isReplaying)
                }
            }

            if let message = syncStore.lastReplayMessage ?? replayCoordinator.lastAutoReplaySummary {
                Section {
                    Text(message)
                        .font(DockWalkTheme.captionFont)
                        .foregroundStyle(DockWalkTheme.textSecondary)
                }
            }
        }
        .navigationTitle("Sync queue")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func queueRow(_ action: QueuedSyncAction) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(action.kindDisplayName)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Tokens.Color.Surface.elevated)
                    .clipShape(Capsule())
                Spacer()
                Text(action.createdAt.formatted(date: .omitted, time: .shortened))
                    .font(DockWalkTheme.captionFont)
                    .foregroundStyle(DockWalkTheme.textSecondary)
            }

            if let barcode = action.primaryBarcode {
                Text(barcode)
                    .font(.system(.body, design: .monospaced).weight(.medium))
            }

            Text(action.summary)
                .font(DockWalkTheme.bodyFont)

            if let loadId = action.inboundLoadId, !loadId.isEmpty {
                Text("Load \(shortId(loadId))")
                    .font(DockWalkTheme.captionFont)
                    .foregroundStyle(DockWalkTheme.textSecondary)
            }

            if let error = action.lastError {
                Text(error)
                    .font(DockWalkTheme.captionFont)
                    .foregroundStyle(DockWalkTheme.danger)
            }
        }
        .padding(.vertical, 4)
    }

    private var autoReplayBinding: Binding<Bool> {
        Binding(
            get: { syncPreferences.receivingEventAutoReplayEnabled },
            set: { newValue in
                syncPreferences.setReceivingEventAutoReplayEnabled(newValue)
                if newValue {
                    Task {
                        await replayCoordinator.handleAutoReplayEnabledByUser(
                            environment: environment,
                            syncStore: syncStore
                        )
                    }
                } else {
                    replayCoordinator.handleAutoReplayDisabledByUser()
                }
            }
        )
    }

    private func shortId(_ id: String) -> String {
        String(id.prefix(8))
    }
}

#Preview {
    NavigationStack {
        SyncQueueView()
            .environment(AppEnvironment.shared)
            .environment(OfflineSyncStore.shared)
            .environment(SyncPreferencesStore.shared)
            .environment(ReceivingEventReplayCoordinator.shared)
    }
}
