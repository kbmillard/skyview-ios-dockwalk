import SwiftUI

/// Today tab shell — dailies content will land here later.
struct TodayDashboard: View {
    @Environment(AppEnvironment.self) private var environment
    @Environment(OfflineSyncStore.self) private var syncStore

    @State private var showSyncQueue = false
    @State private var showActivity = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Tokens.Space.xl) {
                    headerZone
                    dailiesPlaceholderSection
                    systemSection
                }
                .padding(.horizontal, Tokens.Space.base)
                .padding(.bottom, Tokens.Space.xxxl)
            }
            .background(Tokens.Color.Surface.canvas)
            .navigationTitle("Today")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showSyncQueue) {
            NavigationStack {
                SyncQueueView()
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Done") { showSyncQueue = false }
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

    // MARK: - Header

    private var headerZone: some View {
        VStack(alignment: .leading, spacing: Tokens.Space.sm) {
            Text(greeting + ", \(operatorName)")
                .font(Tokens.Font.titleSection)
                .foregroundStyle(Tokens.Color.Ink.primary)

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

    private var operatorName: String {
        environment.userRole.displayName
    }

    private var formattedToday: String {
        Date.now.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day())
    }

    // MARK: - Dailies placeholder

    private var dailiesPlaceholderSection: some View {
        VStack(alignment: .leading, spacing: Tokens.Space.sm) {
            Text("Daily summary")
                .font(Tokens.Font.titleSection)
                .foregroundStyle(Tokens.Color.Ink.primary)

            Text("Dailies will appear here when that workflow is ready.")
                .font(Tokens.Font.bodySecondary)
                .foregroundStyle(Tokens.Color.Ink.tertiary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(Tokens.Space.base)
                .background(cardBackground)
        }
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: Tokens.Radius.card, style: .continuous)
            .fill(Tokens.Color.Surface.card)
            .overlay {
                RoundedRectangle(cornerRadius: Tokens.Radius.card, style: .continuous)
                    .strokeBorder(Tokens.Color.Divider.hairline, lineWidth: 0.5)
            }
    }

    // MARK: - System

    private var systemSection: some View {
        VStack(alignment: .leading, spacing: Tokens.Space.base) {
            Text("System")
                .font(Tokens.Font.titleSection)
                .foregroundStyle(Tokens.Color.Ink.primary)

            SystemRow(
                icon: "arrow.triangle.2.circlepath",
                title: "Sync",
                subtitle: syncSubtitle,
                statusLabel: syncStatusLabel,
                statusColor: syncStatusColor
            ) {
                showSyncQueue = true
            }

            SystemRow(
                icon: "list.bullet.rectangle",
                title: "Activity",
                subtitle: "Trail & pending work"
            ) {
                showActivity = true
            }
        }
    }

    private var syncSubtitle: String {
        if syncStore.pendingSyncableCount > 0 {
            return "\(syncStore.pendingSyncableCount) action(s) queued"
        }
        return "No queued actions"
    }

    private var syncStatusLabel: String? {
        if syncStore.pendingSyncableCount > 0 {
            return "Pending \(syncStore.pendingSyncableCount)"
        }
        return "Up to date"
    }

    private var syncStatusColor: Color? {
        syncStore.pendingSyncableCount > 0 ? Tokens.Color.Signal.warning : nil
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
