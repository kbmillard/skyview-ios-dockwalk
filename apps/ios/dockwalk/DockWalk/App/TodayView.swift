import SwiftUI

struct TodayView: View {
    @Environment(AppEnvironment.self) private var environment
    @Environment(OfflineSyncStore.self) private var syncStore
    @Environment(ScannerPreferencesStore.self) private var scannerPreferences

    @State private var showScanner = false
    @State private var selectedTab: TodayQuickAction?

    private enum TodayQuickAction: String, Identifiable {
        case receiving, scan, ship
        var id: String { rawValue }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DockWalkTheme.sectionSpacing) {
                    header
                    metricsRow
                    syncCard
                    quickActions
                }
                .padding(DockWalkTheme.screenPadding)
            }
            .background(DockWalkTheme.background)
            .navigationTitle("Today")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showScanner) {
                ScannerLabView()
            }
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
            StatusChip(
                label: environment.userRole.displayName,
                tone: .neutral
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var metricsRow: some View {
        HStack(spacing: 12) {
            metricCard(title: "Receiving", value: "4", subtitle: "appointments")
            metricCard(title: "Outbound", value: "6", subtitle: "loads")
            metricCard(title: "Cycle", value: "—", subtitle: "counts")
        }
    }

    private func metricCard(title: String, value: String, subtitle: String) -> some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(DockWalkTheme.captionFont)
                    .foregroundStyle(DockWalkTheme.textSecondary)
                Text(value)
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                Text(subtitle)
                    .font(DockWalkTheme.captionFont)
                    .foregroundStyle(DockWalkTheme.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var syncCard: some View {
        SectionCard {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Sync")
                        .font(DockWalkTheme.headlineFont)
                    Text(syncStore.status.label)
                        .font(DockWalkTheme.bodyFont)
                        .foregroundStyle(DockWalkTheme.textSecondary)
                }
                Spacer()
                StatusChip(label: syncStore.status.chipLabel, tone: syncStore.status.chipTone)
            }
        }
    }

    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick actions")
                .font(DockWalkTheme.headlineFont)

            PrimaryActionButton(title: "Start Receiving", systemImage: "arrow.down.doc.fill") {
                selectedTab = .receiving
            }

            if scannerPreferences.isScannerActive {
                PrimaryActionButton(title: "Scan Item", systemImage: "barcode.viewfinder", style: .secondary) {
                    showScanner = true
                }
            }

            PrimaryActionButton(title: "Ship Order", systemImage: "truck.box.fill", style: .secondary) {
                selectedTab = .ship
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
    TodayView()
        .environment(AppEnvironment.shared)
        .environment(OfflineSyncStore.shared)
}
