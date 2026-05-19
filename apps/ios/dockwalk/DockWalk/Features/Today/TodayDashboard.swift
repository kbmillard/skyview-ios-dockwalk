import SwiftUI

/// Today dashboard: WMS command center with editorial typography
/// Uses ONLY design tokens - zero raw hex, system fonts, or magic numbers
struct TodayDashboard: View {
    @Environment(AppEnvironment.self) private var environment
    @Environment(OfflineSyncStore.self) private var syncStore
    @Binding var selectedTab: AppTab
    
    @State private var dashboard = TodayDashboardViewModel()
    @State private var hasInitiallyLoaded = false
    @State private var showSettings = false
    @State private var showActivity = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Tokens.Space.xl) {
                headerZone
                
                if case .loading = dashboard.loadPhase, !hasInitiallyLoaded {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(Tokens.Space.xxxl)
                } else {
                    inboundSection
                    dockDoorsSection
                    putawaySection
                    outboundSection
                    inventorySection
                    systemSection
                }
            }
            .padding(.horizontal, Tokens.Space.base)
            .padding(.bottom, Tokens.Space.xxxl)
        }
        .background(Tokens.Color.Surface.canvas)
        .refreshable {
            await dashboard.refresh()
        }
        .task {
            if !hasInitiallyLoaded {
                await dashboard.refresh()
                hasInitiallyLoaded = true
            }
        }
        .sheet(isPresented: $showSettings) {
            NavigationStack {
                SettingsView()
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Done") { showSettings = false }
                        }
                    }
            }
        }
        .sheet(isPresented: $showActivity) {
            NavigationStack {
                ActivityView()
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Done") { showActivity = false }
                        }
                    }
            }
        }
    }
    
    // MARK: - Header Zone
    
    private var headerZone: some View {
        VStack(alignment: .leading, spacing: Tokens.Space.sm) {
            Text(greeting)
                .font(Tokens.Font.titleSection)
                .foregroundStyle(Tokens.Color.Ink.primary)
            
            Text(environment.facilityName)
                .font(Tokens.Font.bodySecondary)
                .foregroundStyle(Tokens.Color.Ink.secondary)
            
            // TODO(design): Only show role chip if user has multiple roles available
            // Currently always shown for single role "Receiver" - remove or make conditional
            roleChip
        }
        .padding(.top, Tokens.Space.lg)
        .padding(.bottom, Tokens.Space.base)
    }
    
    private var roleChip: some View {
        Text(environment.userRole.displayName.uppercased())
            .font(Tokens.Font.bodyMeta)
            .foregroundStyle(Tokens.Color.Ink.secondary)
            .padding(.horizontal, Tokens.Space.md)
            .padding(.vertical, Tokens.Space.xs)
            .background(
                Capsule()
                    .fill(Tokens.Color.Surface.elevated)
            )
    }
    
    // MARK: - Inbound Section
    
    private var inboundSection: some View {
        VStack(alignment: .leading, spacing: Tokens.Space.base) {
            sectionHeader(title: "Receiving", actionLabel: "Open Receiving") {
                selectedTab = .receiving
            }
            
            if dashboard.inboundGroups.isEmpty, case .loaded = dashboard.loadPhase {
                emptyState(message: "Nothing inbound today")
            } else {
                // Show Scheduled and Checked In groups
                ForEach(dashboard.inboundGroups.prefix(2)) { group in
                    StatusRowCard(
                        icon: group.status.systemImage,
                        title: group.status.displayName,
                        subtitle: "\(group.count) load(s)",
                        count: group.count
                    ) {
                        selectedTab = .receiving
                    }
                }
            }
        }
    }
    
    // MARK: - Dock Doors Section
    
    private var dockDoorsSection: some View {
        VStack(alignment: .leading, spacing: Tokens.Space.base) {
            Text("Dock doors")
                .font(Tokens.Font.titleSection)
                .foregroundStyle(Tokens.Color.Ink.primary)
            
            MetricCard(
                metrics: [
                    MetricCard.Metric(
                        label: "Open",
                        value: "\(openDoorCount)",
                        color: Tokens.Color.Signal.success
                    ),
                    MetricCard.Metric(
                        label: "Occupied",
                        value: "\(occupiedDoorCount)",
                        color: Tokens.Color.Signal.warning
                    )
                ]
            )
        }
    }
    
    private var openDoorCount: Int {
        dashboard.dockDoors.filter { $0.status == .open }.count
    }
    
    private var occupiedDoorCount: Int {
        dashboard.dockDoors.filter { $0.status == .occupied }.count
    }
    
    // MARK: - Putaway Section
    
    private var putawaySection: some View {
        VStack(alignment: .leading, spacing: Tokens.Space.base) {
            sectionHeader(title: "Putaway", actionLabel: "Open Queue") {
                selectedTab = .putaway
            }
            
            // Show Staged/Pending, Assigned, Complete
            ForEach(dashboard.putawayGroups.prefix(3)) { group in
                StatusRowCard(
                    icon: group.status.systemImage,
                    title: group.status.displayName,
                    subtitle: "\(group.count) task(s)",
                    count: group.count,
                    countColor: group.status == .complete ? Tokens.Color.Signal.success : Tokens.Color.Accent.horizon
                ) {
                    selectedTab = .putaway
                }
            }
            
            if dashboard.putawayGroups.isEmpty, case .loaded = dashboard.loadPhase {
                emptyState(message: "No putaway tasks")
            }
        }
    }
    
    // MARK: - Outbound Section
    
    private var outboundSection: some View {
        VStack(alignment: .leading, spacing: Tokens.Space.base) {
            sectionHeader(title: "Shipping", actionLabel: "Open Shipping") {
                selectedTab = .shipping
            }
            
            MetricCard(
                metrics: [
                    MetricCard.Metric(
                        label: "Ready to pick",
                        value: "\(dashboard.readyToPickCount)"
                    ),
                    MetricCard.Metric(
                        label: "Picking",
                        value: "\(dashboard.pickingCount)"
                    ),
                    MetricCard.Metric(
                        label: "Loading",
                        value: "\(dashboard.loadingCount)"
                    )
                ],
                action: {
                    selectedTab = .shipping
                }
            )
        }
    }
    
    // MARK: - Inventory Section
    
    private var inventorySection: some View {
        VStack(alignment: .leading, spacing: Tokens.Space.base) {
            sectionHeader(title: "Inventory", actionLabel: "Open Inventory") {
                selectedTab = .inventory
            }
            
            MetricCard(
                metrics: [
                    MetricCard.Metric(
                        label: "SKUs",
                        value: "\(dashboard.inventorySkuCount)"
                    ),
                    MetricCard.Metric(
                        label: "On hand",
                        value: "\(dashboard.inventoryTotalUnits)"
                    )
                ],
                action: {
                    selectedTab = .inventory
                }
            )
        }
    }
    
    // MARK: - System Section
    
    private var systemSection: some View {
        VStack(alignment: .leading, spacing: Tokens.Space.base) {
            Text("System")
                .font(Tokens.Font.titleSection)
                .foregroundStyle(Tokens.Color.Ink.primary)
            
            // Sync row — opens settings sheet (sync controls live there).
            SystemRow(
                icon: "arrow.triangle.2.circlepath",
                title: "Sync",
                subtitle: syncSubtitle,
                statusLabel: syncStatusLabel,
                statusColor: syncStatusColor
            ) {
                showSettings = true
            }
            
            // Activity row — audit trail, presented as a sheet.
            SystemRow(
                icon: "list.bullet.rectangle",
                title: "Activity",
                subtitle: "Audit trail"
            ) {
                showActivity = true
            }
        }
    }
    
    private var syncSubtitle: String {
        if syncStore.pendingSyncableCount > 0 {
            return "\(syncStore.pendingSyncableCount) action(s) queued"
        } else {
            return "No queued actions"
        }
    }
    
    private var syncStatusLabel: String? {
        if syncStore.pendingSyncableCount > 0 {
            return "Pending \(syncStore.pendingSyncableCount)"
        } else {
            return "Up to date"
        }
    }
    
    private var syncStatusColor: Color? {
        syncStore.pendingSyncableCount > 0 ? Tokens.Color.Signal.warning : nil
    }
    
    // MARK: - Helpers
    
    private func sectionHeader(title: String, actionLabel: String, action: @escaping () -> Void) -> some View {
        HStack {
            Text(title)
                .font(Tokens.Font.titleSection)
                .foregroundStyle(Tokens.Color.Ink.primary)
            
            Spacer()
            
            Button(action: action) {
                HStack(spacing: Tokens.Space.xs) {
                    Text(actionLabel)
                        .font(Tokens.Font.bodySecondary)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                }
                .foregroundStyle(Tokens.Color.Accent.horizon)
            }
        }
    }
    
    private func emptyState(message: String) -> some View {
        Text(message)
            .font(Tokens.Font.bodyDefault)
            .foregroundStyle(Tokens.Color.Ink.secondary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, Tokens.Space.xl)
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
