import SwiftUI

struct SettingsView: View {
    @Environment(AppEnvironment.self) private var environment
    @Environment(OfflineSyncStore.self) private var syncStore
    @Environment(SyncPreferencesStore.self) private var syncPreferences
    @Environment(ReceivingEventReplayCoordinator.self) private var replayCoordinator
    @State private var showDebug = false

    var body: some View {
        NavigationStack {
            List {
                Section("Facility") {
                    LabeledContent("Name", value: environment.facilityName)
                    LabeledContent("Facility ID", value: environment.facilityId)
                        .font(.system(.body, design: .monospaced))
                    LabeledContent("Organization", value: environment.orgId)
                        .font(.system(.body, design: .monospaced))
                    LabeledContent("Role", value: environment.userRole.displayName)
                }

                Section("API") {
                    LabeledContent("Base URL", value: environment.apiBaseURL.absoluteString)
                        .font(.system(.footnote, design: .monospaced))
                    NavigationLink("API connection…") {
                        APIConnectionSettingsView()
                    }
                    Text("Simulator: localhost · Device: LAN IP or Railway preset.")
                        .font(DockWalkTheme.captionFont)
                        .foregroundStyle(DockWalkTheme.textSecondary)
                }

                Section {
                    if FeatureFlags.isReceivingEventAutoReplayPermitted {
                        Toggle("Auto-replay receiving events", isOn: autoReplayBinding)
                    }
                    if syncStore.pendingReceivingEventCount > 0 {
                        Text("\(syncStore.pendingReceivingEventCount) receiving event(s) queued")
                            .font(DockWalkTheme.captionFont)
                            .foregroundStyle(DockWalkTheme.warning)
                    }
                    HStack {
                        Text("Status")
                        Spacer()
                        StatusChip(label: syncStore.status.chipLabel, tone: syncStore.status.chipTone)
                    }
                    if replayCoordinator.isReplaying {
                        HStack {
                            ProgressView()
                            Text("Replaying receiving events…")
                                .font(DockWalkTheme.captionFont)
                        }
                    }
                    if FeatureFlags.offlineSyncEnabled {
                        Text("\(syncStore.queuedActions.count) total queued action(s)")
                            .font(DockWalkTheme.captionFont)
                            .foregroundStyle(DockWalkTheme.textSecondary)
                    }
                    if let at = replayCoordinator.lastAutoReplayAt {
                        Text("Last auto-replay: \(at.formatted(date: .abbreviated, time: .shortened))")
                            .font(DockWalkTheme.captionFont)
                            .foregroundStyle(DockWalkTheme.textSecondary)
                    }
                    if let summary = replayCoordinator.lastAutoReplaySummary {
                        Text(summary)
                            .font(DockWalkTheme.captionFont)
                            .foregroundStyle(DockWalkTheme.textSecondary)
                    } else if let message = syncStore.lastReplayMessage {
                        Text(message)
                            .font(DockWalkTheme.captionFont)
                            .foregroundStyle(DockWalkTheme.textSecondary)
                    }
                    if let hint = replayCoordinator.pendingAutoReplayHint {
                        Text(hint)
                            .font(DockWalkTheme.captionFont)
                            .foregroundStyle(DockWalkTheme.textSecondary)
                    }
                } header: {
                    Text("Sync")
                } footer: {
                    if FeatureFlags.isReceivingEventAutoReplayPermitted {
                        Text("Replays only queued receiving events after connectivity returns. Other queue kinds are not replayed. Manual replay remains in Debug.")
                            .font(DockWalkTheme.captionFont)
                    }
                }

                Section("Feature flags") {
                    flagRow("AI inspection", enabled: FeatureFlags.aiInspectionEnabled)
                    flagRow("Payments / POS", enabled: FeatureFlags.paymentsEnabled)
                    flagRow("Live scanner", enabled: FeatureFlags.liveScannerEnabled)
                    flagRow("Offline sync", enabled: FeatureFlags.offlineSyncEnabled)
                    flagRow("Debug panel", enabled: FeatureFlags.debugPanelEnabled)
                }

                Section("Activity") {
                    NavigationLink("Audit events") {
                        ActivityView()
                    }
                    Text("Read-only trail from GET /api/audit/events — confirms receiving writes on the server.")
                        .font(DockWalkTheme.captionFont)
                        .foregroundStyle(DockWalkTheme.textSecondary)
                }

                Section("Modules") {
                    NavigationLink("Tasks") { TasksHomeView() }
                    NavigationLink("Exceptions") { ExceptionsHomeView() }
                    NavigationLink("Inspection (stub)") { InspectionStubView() }
                }

                if FeatureFlags.debugPanelEnabled {
                    Section {
                        Button("Open debug panel") {
                            showDebug = true
                        }
                    }
                }
            }
            .navigationTitle("More")
            .sheet(isPresented: $showDebug) {
                NavigationStack {
                    DebugPanelView()
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Done") { showDebug = false }
                            }
                        }
                }
            }
        }
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

    private func flagRow(_ title: String, enabled: Bool) -> some View {
        HStack {
            Text(title)
            Spacer()
            StatusChip(label: enabled ? "On" : "Off", tone: enabled ? .success : .neutral)
        }
    }
}

#Preview {
    SettingsView()
        .environment(AppEnvironment.shared)
        .environment(OfflineSyncStore.shared)
        .environment(SyncPreferencesStore.shared)
        .environment(ReceivingEventReplayCoordinator.shared)
}
