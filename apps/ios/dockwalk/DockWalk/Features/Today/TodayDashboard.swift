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
                    liveNowSection
                    overviewSection
                    quickActionsSection
                    recentWorkSection
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
            Text(greeting + ", Marcus")
                .font(Tokens.Font.titleSection)
                .foregroundStyle(Tokens.Color.Ink.primary)

            HStack(spacing: 4) {
                Text("DockWalk")
                    .font(Tokens.Font.bodySecondary.weight(.semibold))
                    .foregroundStyle(Tokens.Color.Ink.primary)
                Text("by")
                    .font(Tokens.Font.bodySecondary)
                    .foregroundStyle(Tokens.Color.Ink.secondary)
                Text("SkyView")
                    .font(Tokens.Font.bodySecondary.weight(.semibold))
                    .foregroundStyle(Tokens.Color.Accent.horizon)
            }

            HStack(spacing: 6) {
                Image(systemName: "mappin.and.ellipse")
                    .font(.caption)
                    .foregroundStyle(Tokens.Color.Ink.tertiary)
                Text("\(environment.facilityName) · \(formattedToday)")
                    .font(Tokens.Font.bodySecondary)
                    .foregroundStyle(Tokens.Color.Ink.secondary)
            }
        }
        .padding(.top, Tokens.Space.lg)
        .padding(.bottom, Tokens.Space.base)
    }

    private var formattedToday: String {
        Date.now.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day())
    }

    // MARK: - Live Now

    private var liveNowSection: some View {
        LiveNowBanner(item: MockWarehouseFloor.liveNow) {
            selectedTab = .receiving
        }
    }

    // MARK: - Overview

    private var overviewSection: some View {
        VStack(alignment: .leading, spacing: Tokens.Space.base) {
            sectionTitle("Overview")
            FloorOverviewGrid(stats: MockWarehouseFloor.overviewStats)
        }
    }

    // MARK: - Quick actions

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: Tokens.Space.base) {
            sectionTitle("Quick actions")
            QuickActionsRow(actions: MockWarehouseFloor.quickActions) { tab in
                selectedTab = tab
            }
        }
    }

    // MARK: - Recent work

    private var recentWorkSection: some View {
        VStack(alignment: .leading, spacing: Tokens.Space.base) {
            sectionTitle("Recent work")
            RecentWorkFeed(items: MockWarehouseFloor.recentWork)
        }
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title.uppercased())
            .font(Tokens.Font.bodyMeta)
            .tracking(Tokens.Tracking.bodyMeta)
            .foregroundStyle(Tokens.Color.Ink.tertiary)
            .padding(.horizontal, 4)
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

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default: return "Good evening"
        }
    }
}
