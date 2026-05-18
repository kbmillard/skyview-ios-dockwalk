import SwiftUI

struct TodayView: View {
    @Environment(AppEnvironment.self) private var environment
    @Environment(OfflineSyncStore.self) private var syncStore
    @Environment(ScannerPreferencesStore.self) private var scannerPreferences
    @Binding var selectedTab: AppTab

    @State private var dashboard = TodayDashboardViewModel()
    @State private var showScanner = false
    @State private var hasInitiallyLoaded = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DockWalkTheme.sectionSpacing) {
                    header
                    
                    if case .loading = dashboard.loadPhase, !hasInitiallyLoaded {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else {
                        inboundSection
                        dockDoorsSection
                        putawaySection
                        outboundSection
                        inventorySection
                        systemSection
                    }
                }
                .padding(DockWalkTheme.screenPadding)
            }
            .background(DockWalkTheme.background)
            .navigationTitle("Today")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                await dashboard.refresh()
            }
            .task {
                if !hasInitiallyLoaded {
                    await dashboard.refresh()
                    hasInitiallyLoaded = true
                }
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

    // MARK: - Header
    
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

    // MARK: - Inbound Section
    
    private var inboundSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Inbound")
                    .font(DockWalkTheme.headlineFont)
                Spacer()
                Button {
                    selectedTab = .receive
                } label: {
                    HStack(spacing: 4) {
                        Text("Open Receive")
                            .font(DockWalkTheme.captionFont)
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                    }
                    .foregroundStyle(DockWalkTheme.accent)
                }
            }
            
            ForEach(dashboard.inboundGroups) { group in
                inboundGroupCard(group)
            }
            
            if dashboard.inboundGroups.isEmpty, case .loaded = dashboard.loadPhase {
                SectionCard {
                    Text("No inbound loads — check Receive for appointments.")
                        .font(DockWalkTheme.bodyFont)
                        .foregroundStyle(DockWalkTheme.textSecondary)
                }
            }
        }
    }
    
    private func inboundGroupCard(_ group: InboundLoadGroup) -> some View {
        Button {
            selectedTab = .receive
        } label: {
            SectionCard {
                HStack {
                    Image(systemName: group.status.systemImage)
                        .font(.title2)
                        .foregroundStyle(DockWalkTheme.accent)
                        .frame(width: 32)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(group.status.displayName)
                            .font(DockWalkTheme.headlineFont)
                            .foregroundStyle(DockWalkTheme.textPrimary)
                        Text("\(group.count) load(s)")
                            .font(DockWalkTheme.captionFont)
                            .foregroundStyle(DockWalkTheme.textSecondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(DockWalkTheme.textSecondary)
                }
            }
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Dock Doors Section
    
    private var dockDoorsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Dock doors")
                .font(DockWalkTheme.headlineFont)
            
            HStack(spacing: 12) {
                let openCount = dashboard.dockDoors.filter { $0.status == .open }.count
                let occupiedCount = dashboard.dockDoors.filter { $0.status == .occupied }.count
                
                SectionCard {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Open")
                            .font(DockWalkTheme.captionFont)
                            .foregroundStyle(DockWalkTheme.textSecondary)
                        Text("\(openCount)")
                            .font(.system(size: 28, weight: .semibold, design: .rounded))
                            .foregroundStyle(DockWalkTheme.success)
                    }
                }
                
                SectionCard {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Occupied")
                            .font(DockWalkTheme.captionFont)
                            .foregroundStyle(DockWalkTheme.textSecondary)
                        Text("\(occupiedCount)")
                            .font(.system(size: 28, weight: .semibold, design: .rounded))
                            .foregroundStyle(DockWalkTheme.warning)
                    }
                }
            }
            
            Text("Dock door assignment and tracking — foundation preview using stable local data.")
                .font(DockWalkTheme.captionFont)
                .foregroundStyle(DockWalkTheme.textSecondary)
        }
    }
    
    // MARK: - Putaway Section
    
    private var putawaySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Putaway")
                    .font(DockWalkTheme.headlineFont)
                Spacer()
                Button {
                    selectedTab = .putaway
                } label: {
                    HStack(spacing: 4) {
                        Text("Open Queue")
                            .font(DockWalkTheme.captionFont)
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                    }
                    .foregroundStyle(DockWalkTheme.accent)
                }
            }
            
            if syncStore.pendingTaskActionCount > 0 {
                SectionCard {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(DockWalkTheme.warning)
                        Text("\(syncStore.pendingTaskActionCount) task action(s) queued for sync")
                            .font(DockWalkTheme.bodyFont)
                        Spacer()
                        Button("Sync") {
                            selectedTab = .more
                        }
                        .font(DockWalkTheme.captionFont.weight(.semibold))
                    }
                }
            }
            
            ForEach(dashboard.putawayGroups.prefix(4)) { group in
                putawayGroupCard(group)
            }
            
            if dashboard.putawayGroups.isEmpty, case .loaded = dashboard.loadPhase {
                SectionCard {
                    Text("No putaway tasks — check Putaway tab for queue.")
                        .font(DockWalkTheme.bodyFont)
                        .foregroundStyle(DockWalkTheme.textSecondary)
                }
            }
        }
    }
    
    private func putawayGroupCard(_ group: PutawayQueueGroup) -> some View {
        Button {
            selectedTab = .putaway
        } label: {
            SectionCard {
                HStack {
                    Image(systemName: group.status.systemImage)
                        .font(.title3)
                        .foregroundStyle(DockWalkTheme.accent)
                        .frame(width: 28)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(group.status.displayName)
                            .font(DockWalkTheme.bodyFont)
                            .foregroundStyle(DockWalkTheme.textPrimary)
                    }
                    
                    Spacer()
                    
                    StatusChip(label: "\(group.count)", tone: group.status.chipTone)
                }
            }
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Outbound Section
    
    private var outboundSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Outbound")
                    .font(DockWalkTheme.headlineFont)
                Spacer()
                Button {
                    selectedTab = .ship
                } label: {
                    HStack(spacing: 4) {
                        Text("Open Ship")
                            .font(DockWalkTheme.captionFont)
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                    }
                    .foregroundStyle(DockWalkTheme.accent)
                }
            }
            
            SectionCard {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Pick, stage, load, and closeout")
                        .font(DockWalkTheme.bodyFont)
                    Text("Outbound workflow structure ready — full integration in Phase 2.")
                        .font(DockWalkTheme.captionFont)
                        .foregroundStyle(DockWalkTheme.textSecondary)
                }
            }
        }
    }
    
    // MARK: - Inventory Section
    
    private var inventorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Inventory")
                .font(DockWalkTheme.headlineFont)
            
            NavigationLink {
                InventoryHomeView()
            } label: {
                SectionCard {
                    HStack {
                        Image(systemName: "shippingbox.fill")
                            .font(.title2)
                            .foregroundStyle(DockWalkTheme.accent)
                            .frame(width: 32)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Location lookup & cycle count")
                                .font(DockWalkTheme.headlineFont)
                                .foregroundStyle(DockWalkTheme.textPrimary)
                            Text("On-hand search, movement history, count structure.")
                                .font(DockWalkTheme.captionFont)
                                .foregroundStyle(DockWalkTheme.textSecondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(DockWalkTheme.textSecondary)
                    }
                }
            }
            .buttonStyle(.plain)
        }
    }
    
    // MARK: - System Section
    
    private var systemSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("System")
                .font(DockWalkTheme.headlineFont)
            
            Button {
                selectedTab = .more
            } label: {
                SectionCard {
                    HStack {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.title3)
                            .foregroundStyle(syncStore.status.chipTone == .warning ? DockWalkTheme.warning : DockWalkTheme.accent)
                            .frame(width: 28)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Sync")
                                .font(DockWalkTheme.bodyFont)
                                .foregroundStyle(DockWalkTheme.textPrimary)
                            if syncStore.pendingSyncableCount > 0 {
                                Text("\(syncStore.pendingSyncableCount) action(s) queued")
                                    .font(DockWalkTheme.captionFont)
                                    .foregroundStyle(DockWalkTheme.textSecondary)
                            } else {
                                Text("No queued actions")
                                    .font(DockWalkTheme.captionFont)
                                    .foregroundStyle(DockWalkTheme.textSecondary)
                            }
                        }
                        
                        Spacer()
                        
                        StatusChip(label: syncStore.status.chipLabel, tone: syncStore.status.chipTone)
                    }
                }
            }
            .buttonStyle(.plain)
            
            NavigationLink {
                ActivityView()
            } label: {
                SectionCard {
                    HStack {
                        Image(systemName: "list.bullet.rectangle")
                            .font(.title3)
                            .foregroundStyle(DockWalkTheme.accent)
                            .frame(width: 28)
                        
                        Text("Activity")
                            .font(DockWalkTheme.bodyFont)
                            .foregroundStyle(DockWalkTheme.textPrimary)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(DockWalkTheme.textSecondary)
                    }
                }
            }
            .buttonStyle(.plain)
            
            if scannerPreferences.isScannerActive {
                Button {
                    showScanner = true
                } label: {
                    SectionCard {
                        HStack {
                            Image(systemName: "barcode.viewfinder")
                                .font(.title3)
                                .foregroundStyle(DockWalkTheme.accent)
                                .frame(width: 28)
                            
                            Text("Scanner Lab")
                                .font(DockWalkTheme.bodyFont)
                                .foregroundStyle(DockWalkTheme.textPrimary)
                            
                            Spacer()
                            
                            StatusChip(label: "On", tone: .success)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
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
