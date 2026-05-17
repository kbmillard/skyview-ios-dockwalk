import SwiftUI

struct SettingsView: View {
    @Environment(AppEnvironment.self) private var environment
    @Environment(OfflineSyncStore.self) private var syncStore
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

                Section("Sync") {
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
                    if syncStore.pendingReceivingEventCount > 0 {
                        Text("\(syncStore.pendingReceivingEventCount) receiving event(s) queued")
                            .font(DockWalkTheme.captionFont)
                            .foregroundStyle(DockWalkTheme.warning)
                    }
                    if FeatureFlags.offlineSyncEnabled {
                        Text("\(syncStore.queuedActions.count) total queued action(s)")
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
                }

                Section("Feature flags") {
                    flagRow("AI inspection", enabled: FeatureFlags.aiInspectionEnabled)
                    flagRow("Payments / POS", enabled: FeatureFlags.paymentsEnabled)
                    flagRow("Live scanner", enabled: FeatureFlags.liveScannerEnabled)
                    flagRow("Offline sync", enabled: FeatureFlags.offlineSyncEnabled)
                    flagRow("Auto-replay receiving", enabled: FeatureFlags.autoReplayReceivingEventsEnabled)
                    flagRow("Debug panel", enabled: FeatureFlags.debugPanelEnabled)
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
        .environment(ReceivingEventReplayCoordinator.shared)
}
