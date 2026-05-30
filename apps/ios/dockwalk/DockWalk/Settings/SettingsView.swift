import SwiftUI

struct SettingsView: View {
    @Environment(AppEnvironment.self) private var environment
    @Environment(ThemeStore.self) private var themeStore
    @Environment(OfflineSyncStore.self) private var syncStore
    @Environment(SyncPreferencesStore.self) private var syncPreferences
    @Environment(ScannerPreferencesStore.self) private var scannerPreferences
    @Environment(ReceivingEventReplayCoordinator.self) private var replayCoordinator
    @State private var showDebug = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("Facility, sync, API, and debug tools. Day-to-day work lives on Today, Receive, and Putaway.")
                        .font(DockWalkTheme.captionFont)
                        .foregroundStyle(DockWalkTheme.textSecondary)
                }

                Section("Facility") {
                    LabeledContent("Name", value: environment.facilityName)
                    LabeledContent("Facility ID", value: environment.facilityId)
                        .font(.system(.body, design: .monospaced))
                    LabeledContent("Organization", value: environment.orgId)
                        .font(.system(.body, design: .monospaced))
                    LabeledContent("Role", value: environment.userRole.displayName)
                }

                Section("Theme") {
                    Picker("Profile", selection: themeProfileBinding) {
                        ForEach(ThemeProfile.allCases) { profile in
                            Text(profile.displayName).tag(profile)
                        }
                    }
                    Text("Facility default: DockWalk Classic. This device can override locally.")
                        .font(DockWalkTheme.captionFont)
                        .foregroundStyle(DockWalkTheme.textSecondary)
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
                    if syncStore.pendingTaskActionCount > 0 {
                        Text("\(syncStore.pendingTaskActionCount) putaway task action(s) queued")
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
                            Text("Replaying offline queue…")
                                .font(DockWalkTheme.captionFont)
                        }
                    }
                    if FeatureFlags.offlineSyncEnabled {
                        if syncStore.pendingSyncableCount == 0 {
                            Text("No queued actions.")
                                .font(DockWalkTheme.captionFont)
                                .foregroundStyle(DockWalkTheme.textSecondary)
                        } else {
                            Text("\(syncStore.queuedActions.count) total queued action(s)")
                                .font(DockWalkTheme.captionFont)
                                .foregroundStyle(DockWalkTheme.textSecondary)
                        }
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
                    NavigationLink("Sync queue") {
                        SyncQueueView()
                    }
                } header: {
                    Text("Sync")
                } footer: {
                    #if DEBUG
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Auto-replay is for offline queue sync only — not the barcode scanner.")
                            .font(DockWalkTheme.captionFont)
                        if FeatureFlags.isReceivingEventAutoReplayPermitted {
                            Text(
                                FeatureFlags.syncBatchReplayEnabled
                                    ? "Replay uses batch sync for receiving events and putaway task actions."
                                    : "Replays queued receiving events one at a time."
                            )
                            .font(DockWalkTheme.captionFont)
                        }
                    }
                    #else
                    Text("Auto-replay sends queued work when the device is back online.")
                        .font(DockWalkTheme.captionFont)
                    #endif
                }

                Section("Activity") {
                    NavigationLink("Audit events") {
                        ActivityView()
                    }
                    Text("Read-only audit trail from the DockWalk API.")
                        .font(DockWalkTheme.captionFont)
                        .foregroundStyle(DockWalkTheme.textSecondary)
                }

                if scannerPreferences.isScannerActive {
                    Section("Scanner (QA)") {
                        NavigationLink("Scanner Lab") {
                            ScannerLabView()
                        }
                        Button("Turn off scanner on this device", role: .destructive) {
                            scannerPreferences.setInternalScannerEnabled(false)
                        }
                        .font(DockWalkTheme.captionFont)
                    }
                }

                Section("Feature flags") {
                    flagRow("AI inspection", enabled: FeatureFlags.aiInspectionEnabled)
                    flagRow("Payments / POS", enabled: FeatureFlags.paymentsEnabled)
                    flagRow("Live scanner (compile)", enabled: FeatureFlags.liveScannerEnabled)
                    flagRow("Scanner on device", enabled: scannerPreferences.isScannerActive)
                    flagRow("Offline sync", enabled: FeatureFlags.offlineSyncEnabled)
                    flagRow("Batch sync replay", enabled: FeatureFlags.syncBatchReplayEnabled)
                    flagRow("Debug panel", enabled: FeatureFlags.debugPanelEnabled)
                }

                if FeatureFlags.debugPanelEnabled {
                    Section("Debug") {
                        Button("Open debug panel") {
                            showDebug = true
                        }
                        NavigationLink("Exceptions (stub)") { ExceptionsHomeView() }
                        NavigationLink("Inspection (stub)") { InspectionStubView() }
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

    private var themeProfileBinding: Binding<ThemeProfile> {
        Binding(
            get: { themeStore.profile },
            set: { themeStore.setProfile($0) }
        )
    }
}

#Preview {
    SettingsView()
        .environment(AppEnvironment.shared)
        .environment(OfflineSyncStore.shared)
        .environment(ThemeStore.shared)
        .environment(SyncPreferencesStore.shared)
        .environment(ScannerPreferencesStore.shared)
        .environment(ReceivingEventReplayCoordinator.shared)
}
