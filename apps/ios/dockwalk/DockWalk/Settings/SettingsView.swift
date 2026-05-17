import SwiftUI

struct SettingsView: View {
    @Environment(AppEnvironment.self) private var environment
    @Environment(OfflineSyncStore.self) private var syncStore
    @State private var showDebug = false

    var body: some View {
        NavigationStack {
            List {
                Section("Facility") {
                    LabeledContent("Name", value: environment.facilityName)
                    LabeledContent("Facility ID", value: environment.facilityId)
                    LabeledContent("Organization", value: environment.orgId)
                    LabeledContent("Role", value: environment.userRole.displayName)
                }

                Section("API") {
                    LabeledContent("Base URL", value: environment.apiBaseURL.absoluteString)
                    Text("Live networking is stubbed; ViewModels use local demo data until Phase 1A.")
                        .font(DockWalkTheme.captionFont)
                        .foregroundStyle(DockWalkTheme.textSecondary)
                }

                Section("Sync") {
                    HStack {
                        Text("Status")
                        Spacer()
                        StatusChip(label: syncStore.status.chipLabel, tone: syncStore.status.chipTone)
                    }
                    if FeatureFlags.offlineSyncEnabled {
                        Text("\(syncStore.queuedActions.count) queued action(s)")
                    }
                }

                Section("Feature flags") {
                    flagRow("AI inspection", enabled: FeatureFlags.aiInspectionEnabled)
                    flagRow("Payments / POS", enabled: FeatureFlags.paymentsEnabled)
                    flagRow("Live scanner", enabled: FeatureFlags.liveScannerEnabled)
                    flagRow("Offline sync", enabled: FeatureFlags.offlineSyncEnabled)
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
}
