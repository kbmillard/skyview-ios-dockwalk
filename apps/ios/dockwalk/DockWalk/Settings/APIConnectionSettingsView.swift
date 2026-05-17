import SwiftUI

struct APIConnectionSettingsView: View {
    @Environment(AppEnvironment.self) private var environment

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
                Text("Physical device: use your Mac’s LAN IP, e.g. `http://192.168.1.42:8790` — not localhost.")
            }
            .font(DockWalkTheme.captionFont)
            .foregroundStyle(DockWalkTheme.textSecondary)

            Section("DockWalk API") {
                TextField("API base URL", text: $apiBaseURLString)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.URL)
                TextField("Organization ID", text: $orgId)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                TextField("Facility ID", text: $facilityId)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
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
        } catch {
            connectionPhase = .failure(error.localizedDescription)
        }
    }
}

#Preview {
    NavigationStack {
        APIConnectionSettingsView()
            .environment(AppEnvironment.shared)
    }
}
