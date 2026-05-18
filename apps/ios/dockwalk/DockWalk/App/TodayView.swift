import SwiftUI

struct TodayView: View {
    @Environment(AppEnvironment.self) private var environment
    @Environment(OfflineSyncStore.self) private var syncStore
    @Environment(ScannerPreferencesStore.self) private var scannerPreferences
    @Binding var selectedTab: AppTab

    @State private var dashboard = TodayDashboardViewModel()
    @State private var showScanner = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DockWalkTheme.sectionSpacing) {
                    header
                    operationalSection
                    foundationSection
                }
                .padding(DockWalkTheme.screenPadding)
            }
            .background(DockWalkTheme.background)
            .navigationTitle("Today")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                await dashboard.refresh()
            }
            .task(id: environment.configRevision) {
                await dashboard.refresh()
            }
            .sheet(isPresented: $showScanner) {
                NavigationStack {
                    ScannerLabView()
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Done") { showScanner = false }
                            }
                        }
                }
            }
            .dismissScannerSheetWhenInactive(scannerPreferences, isPresented: $showScanner)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(greeting)
                .font(DockWalkTheme.titleFont)
                .foregroundStyle(DockWalkTheme.textPrimary)
            Text(environment.facilityName)
                .font(DockWalkTheme.subtitleFont)
                .foregroundStyle(DockWalkTheme.textSecondary)
            StatusChip(label: environment.userRole.displayName, tone: .neutral)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var operationalSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Dock work")
                .font(DockWalkTheme.headlineFont)

            OperationalDestinationCard(
                title: "Receive",
                subtitle: receiveSubtitle,
                systemImage: "arrow.down.to.line",
                statusLabel: receiveStatusLabel,
                statusTone: receiveStatusTone
            ) {
                selectedTab = .receive
            }

            OperationalDestinationCard(
                title: "Putaway",
                subtitle: putawaySubtitle,
                systemImage: "arrow.left.arrow.right.square",
                statusLabel: putawayStatusLabel,
                statusTone: .info
            ) {
                selectedTab = .putaway
            }

            OperationalDestinationCard(
                title: "Sync",
                subtitle: syncSubtitle,
                systemImage: "arrow.triangle.2.circlepath",
                statusLabel: syncStore.status.chipLabel,
                statusTone: syncStore.status.chipTone
            ) {
                selectedTab = .more
            }

            NavigationLink {
                ActivityView()
            } label: {
                OperationalDestinationCard(
                    title: "Activity",
                    subtitle: "Audit trail from the DockWalk API.",
                    systemImage: "list.bullet.rectangle"
                )
            }

            if scannerPreferences.isScannerActive {
                OperationalDestinationCard(
                    title: "Scanner Lab",
                    subtitle: "Barcode and QR capture for dock labels (QA).",
                    systemImage: "barcode.viewfinder",
                    statusLabel: "On",
                    statusTone: .success
                ) {
                    showScanner = true
                }
            }
        }
    }

    private var foundationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Inventory & outbound")
                .font(DockWalkTheme.headlineFont)

            NavigationLink {
                InventoryHomeView()
            } label: {
                OperationalDestinationCard(
                    title: "Inventory",
                    subtitle: inventorySubtitle,
                    systemImage: "shippingbox.fill",
                    statusLabel: inventoryStatusLabel,
                    statusTone: .neutral
                )
            }

            OperationalDestinationCard(
                title: "Ship",
                subtitle: "Pick, stage, load verification, and closeout for outbound loads.",
                systemImage: "arrow.up.to.line",
                statusLabel: "Preview",
                statusTone: .neutral
            ) {
                selectedTab = .ship
            }
        }
    }
    
    private var inventorySubtitle: String {
        "Location lookup, on-hand search, cycle count — foundation preview."
    }
    
    private var inventoryStatusLabel: String? {
        "Preview"
    }

    private var receiveSubtitle: String {
        switch dashboard.loadPhase {
        case .loaded:
            if let count = dashboard.appointmentCount {
                return "\(count) appointment(s) on the Receive tab — open a shipment to record lines."
            }
            return "Open the Receive tab to work appointments and shipments."
        case .error(let message):
            return message
        default:
            return "Inbound appointments and shipment receiving."
        }
    }

    private var receiveStatusLabel: String? {
        if syncStore.pendingReceivingEventCount > 0 {
            return "\(syncStore.pendingReceivingEventCount) queued"
        }
        if case .loaded = dashboard.loadPhase, let count = dashboard.appointmentCount {
            return "\(count) apt"
        }
        return nil
    }

    private var receiveStatusTone: StatusChip.Tone {
        syncStore.pendingReceivingEventCount > 0 ? .warning : .info
    }

    private var putawaySubtitle: String {
        if syncStore.pendingTaskActionCount > 0 {
            return "\(syncStore.pendingTaskActionCount) putaway action(s) queued — open Putaway or replay from More."
        }
        switch dashboard.loadPhase {
        case .loaded:
            if let count = dashboard.putawayTaskCount {
                return "\(count) task(s) on the Putaway tab — assign, start, block, or complete."
            }
            return "Warehouse putaway tasks for this facility."
        case .error:
            return "Putaway tasks — pull to refresh counts."
        default:
            return "Warehouse putaway tasks for this facility."
        }
    }

    private var putawayStatusLabel: String? {
        if syncStore.pendingTaskActionCount > 0 {
            return "\(syncStore.pendingTaskActionCount) queued"
        }
        if case .loaded = dashboard.loadPhase, let count = dashboard.putawayTaskCount {
            return "\(count) tasks"
        }
        return nil
    }

    private var syncSubtitle: String {
        if syncStore.pendingSyncableCount == 0 {
            return "No queued actions. Open More for sync settings and Debug replay."
        }
        return "\(syncStore.pendingSyncableCount) action(s) queued — More → Sync or Debug replay."
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default: return "Good evening"
        }
    }
}

#Preview {
    TodayView(selectedTab: .constant(.today))
        .environment(AppEnvironment.shared)
        .environment(OfflineSyncStore.shared)
        .environment(ScannerPreferencesStore.shared)
}
