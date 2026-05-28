import SwiftUI

struct DebugPanelView: View {
    @Environment(AppEnvironment.self) private var environment
    @Environment(OfflineSyncStore.self) private var syncStore
    @Environment(ScannerPreferencesStore.self) private var scannerPreferences
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

            Section {
                NavigationLink {
                    SyncQueueView()
                } label: {
                    HStack {
                        Text("Sync queue")
                        Spacer()
                        if syncStore.pendingSyncableCount > 0 {
                            Text("\(syncStore.pendingSyncableCount)")
                                .font(DockWalkTheme.captionFont.weight(.semibold))
                                .foregroundStyle(DockWalkTheme.warning)
                        }
                    }
                }
            } footer: {
                Text("Replay and auto-replay live in Sync queue (Today → Sync or More → Sync).")
                    .font(DockWalkTheme.captionFont)
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
    }
}
