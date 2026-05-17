import SwiftUI

struct APIConnectionSettingsView: View {
    @Environment(AppEnvironment.self) private var environment
    @Environment(OfflineSyncStore.self) private var syncStore
    @Environment(ReceivingEventReplayCoordinator.self) private var replayCoordinator

    @State private var apiBaseURLString: String = ""
    @State private var orgId: String = ""
    @State private var facilityId: String = ""
    @State private var saveMessage: String?
    @State private var connectionPhase: ConnectionTestPhase = .idle

    private enum ConnectionTestPhase: Equatable {
        case idle
        case testing
        case success(HealthResponse)
        case failure(String)
    }

    var body: some View {
        Form {
            Section {
                Text("Simulator: use `http://localhost:8790` while the DockWalk API runs on your Mac.")
                Text("Physical device (local API): use your Mac’s LAN IP, e.g. `http://192.168.1.42:8790` — not localhost.")
                Text("Production: Railway deploy — tap below, then Save & apply and Test.")
            }
            .font(DockWalkTheme.captionFont)
            .foregroundStyle(DockWalkTheme.textSecondary)

            Section("Quick presets") {
                Button("Use Railway production") {
                    apiBaseURLString = DeviceConfiguration.railwayProductionAPIBaseURL
                    saveMessage = "Railway URL filled — tap Save & apply, then Test API connection."
                    connectionPhase = .idle
                }
                Button("Use local simulator API") {
                    apiBaseURLString = DeviceConfiguration.devDefaults.apiBaseURLString
                    saveMessage = "Localhost filled — run `npm run dev` in dockwalk-api, then Save & apply."
                    connectionPhase = .idle
                }
            }

            Section {
                VStack(alignment: .leading, spacing: 6) {
                    Text("API base URL")
                        .font(DockWalkTheme.captionFont)
                        .foregroundStyle(DockWalkTheme.textSecondary)
                    TextField("https://… or http://localhost:8790", text: $apiBaseURLString)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                        .font(.system(.body, design: .monospaced))
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text("Organization ID")
                        .font(DockWalkTheme.captionFont)
                        .foregroundStyle(DockWalkTheme.textSecondary)
                    TextField("org UUID", text: $orgId)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .font(.system(.footnote, design: .monospaced))
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text("Facility ID")
                        .font(DockWalkTheme.captionFont)
                        .foregroundStyle(DockWalkTheme.textSecondary)
                    TextField("facility UUID", text: $facilityId)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .font(.system(.footnote, design: .monospaced))
                }
            } header: {
                Text("DockWalk API")
            } footer: {
                Text("Dev seed org/facility match Railway smoke data when using production API.")
                    .font(DockWalkTheme.captionFont)
            }

            Section {
                Button("Save & apply") {
                    saveConfiguration()
                }
                Button("Reset to dev defaults", role: .destructive) {
                    environment.resetToDevDefaults()
                    loadFromEnvironment()
                    saveMessage = "Restored dev defaults."
                    connectionPhase = .idle
                }
            }

            if let saveMessage {
                Section {
                    Text(saveMessage)
                        .font(DockWalkTheme.captionFont)
                        .foregroundStyle(DockWalkTheme.textSecondary)
                }
            }

            Section("Connection test") {
                Button {
                    Task { await testConnection() }
                } label: {
                    HStack {
                        Text("Test API connection")
                        Spacer()
                        if connectionPhase == .testing {
                            ProgressView()
                        }
                    }
                }
                .disabled(connectionPhase == .testing)

                connectionResultView
            }
        }
        .navigationTitle("API connection")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadFromEnvironment()
        }
    }

    @ViewBuilder
    private var connectionResultView: some View {
        switch connectionPhase {
        case .idle:
            Text("Calls GET /health only — no auth or service-role secrets.")
                .font(DockWalkTheme.captionFont)
                .foregroundStyle(DockWalkTheme.textSecondary)
        case .testing:
            Text("Testing…")
                .font(DockWalkTheme.captionFont)
        case .success(let health):
            VStack(alignment: .leading, spacing: 6) {
                StatusChip(label: "Connected", tone: .success)
                LabeledContent("Status", value: health.status ?? "—")
                LabeledContent("Service", value: health.service ?? "—")
                LabeledContent("Supabase", value: health.supabase ?? "—")
                if let env = health.environment {
                    LabeledContent("API env", value: env)
                }
                Text(
                    health.supabase == "configured"
                        ? "Server can reach Supabase (egas) — list routes may return live data."
                        : "Server reports stub — lists may be empty until Supabase is configured."
                )
                .font(DockWalkTheme.captionFont)
                .foregroundStyle(DockWalkTheme.textSecondary)
            }
        case .failure(let message):
            VStack(alignment: .leading, spacing: 6) {
                StatusChip(label: "Failed", tone: .danger)
                Text(message)
                    .font(DockWalkTheme.captionFont)
                    .foregroundStyle(DockWalkTheme.textSecondary)
            }
        }
    }

    private func loadFromEnvironment() {
        let config = environment.currentConfiguration
        apiBaseURLString = config.apiBaseURLString
        orgId = config.orgId
        facilityId = config.facilityId
    }

    private func saveConfiguration() {
        if let error = environment.apply(
            apiBaseURLString: apiBaseURLString,
            orgId: orgId,
            facilityId: facilityId
        ) {
            saveMessage = error
            return
        }
        loadFromEnvironment()
        saveMessage = "Saved. Pull to refresh on Receive to load appointments with the new settings."
        connectionPhase = .idle
    }

    private func testConnection() async {
        connectionPhase = .testing
        let draft = DeviceConfiguration.normalized(
            apiBaseURLString: apiBaseURLString,
            orgId: orgId,
            facilityId: facilityId,
            facilityName: environment.facilityName
        )
        guard let url = draft.apiBaseURL else {
            connectionPhase = .failure("Enter a valid API base URL before testing.")
            return
        }
        let client = APIClient(baseURL: url)
        do {
            let health = try await client.fetchHealth()
            connectionPhase = .success(health)
            await replayCoordinator.attemptAutoReplayIfNeeded(
                environment: environment,
                syncStore: syncStore,
                trigger: "health_ok"
            )
        } catch {
            connectionPhase = .failure(error.localizedDescription)
        }
    }
}

#Preview {
    NavigationStack {
        APIConnectionSettingsView()
            .environment(AppEnvironment.shared)
            .environment(OfflineSyncStore.shared)
            .environment(SyncPreferencesStore.shared)
            .environment(ReceivingEventReplayCoordinator.shared)
}
}
