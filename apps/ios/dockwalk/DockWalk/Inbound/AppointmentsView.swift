import SwiftUI

struct AppointmentsView: View {
    @Environment(AppEnvironment.self) private var environment
    @Environment(OfflineSyncStore.self) private var syncStore
    @Environment(ReceivingEventReplayCoordinator.self) private var replayCoordinator
    @Environment(DemoOperationalDataStore.self) private var demoOperationalData
    @Environment(InboundSessionStore.self) private var inboundSession
    @Environment(AppointmentsViewModel.self) private var viewModel

    @State private var showingCreateLoad = false
    @State private var didInitialLoad = false

    private let calendar = Calendar.current

    private var selectedStage: InboundStageFilter {
        get {
            InboundStageFilter(rawValue: inboundSession.selectedStageRaw) ?? .scheduled
        }
    }

    private var selectedScheduleDay: Date {
        inboundSession.selectedScheduleDay
    }

    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.loadPhase == .loaded {
                    ScrollView {
                        VStack(spacing: 0) {
                            weekScheduleStrip
                            stageTabs
                            loadsList
                        }
                    }
                } else {
                    LoadStateView(phase: viewModel.loadPhase) {
                        Task { await loadInbound(forceReseedDemo: false) }
                    }
                }

                if case .loading = viewModel.loadPhase {
                    LoadStateView(phase: .loading)
                        .background(.ultraThinMaterial)
                }
            }
            .navigationTitle("Inbound")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingCreateLoad = true
                    } label: {
                        Label("Create Load", systemImage: "plus")
                    }
                }
            }
            .refreshable {
                await loadInbound(forceReseedDemo: true)
            }
            .safeAreaInset(edge: .top) {
                statusBanner
            }
            .sheet(isPresented: $showingCreateLoad) {
                CreateLoadView(viewModel: viewModel)
            }
        }
        .task(id: environment.configRevision) {
            await loadOnceIfNeeded()
        }
        .onChange(of: demoOperationalData.revision) { _, _ in
            inboundSession.resetDemoLoads()
            didInitialLoad = false
            Task { await loadInbound(forceReseedDemo: false) }
        }
        .id(inboundSession.revision)
    }

    private func loadOnceIfNeeded() async {
        guard !didInitialLoad else { return }
        didInitialLoad = true
        await loadInbound(forceReseedDemo: false)
    }

    private func loadInbound(forceReseedDemo: Bool) async {
        await viewModel.refresh(syncStore: syncStore, forceReseedDemo: forceReseedDemo)
    }

    private func setSelectedStage(_ stage: InboundStageFilter) {
        inboundSession.selectedStageRaw = stage.rawValue
    }

    private func setSelectedScheduleDay(_ day: Date) {
        inboundSession.selectedScheduleDay = day
    }

    private var weekScheduleStrip: some View {
        InboundWeekScheduleStrip(
            weekDays: InboundWeekSchedule.weekDays(containing: selectedScheduleDay, calendar: calendar),
            selectedDay: selectedScheduleDay,
            scheduledCount: { day in
                scheduledLoads(on: day).count
            },
            onSelectDay: { setSelectedScheduleDay($0) }
        )
    }

    private var stageTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(InboundStageFilter.allCases) { stage in
                    StageTabButton(
                        stage: stage,
                        count: countForStageTab(stage),
                        isSelected: selectedStage == stage
                    ) {
                        setSelectedStage(stage)
                    }
                }
            }
            .padding(.horizontal, DockWalkTheme.screenPadding)
            .padding(.vertical, 12)
        }
        .background(DockWalkTheme.background)
    }

    private var loadsList: some View {
        VStack(spacing: 12) {
            let loads = loadsForStage(selectedStage)
            if loads.isEmpty {
                emptyStageView
                    .padding(.vertical, 40)
            } else {
                ForEach(loads) { load in
                    if let binding = loadBinding(for: load) {
                        NavigationLink {
                            LoadDetailView(
                                load: binding,
                                viewModel: viewModel,
                                environment: environment
                            )
                        } label: {
                            loadRow(load)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, DockWalkTheme.screenPadding)
            }
        }
    }

    private var emptyStageView: some View {
        VStack(spacing: 8) {
            Image(systemName: selectedStage.status.systemImage)
                .font(.system(size: 48))
                .foregroundStyle(DockWalkTheme.textSecondary.opacity(0.5))
            if selectedStage == .scheduled {
                Text("No scheduled loads on \(selectedScheduleDay.formatted(date: .abbreviated, time: .omitted))")
                    .font(DockWalkTheme.bodyFont)
                    .foregroundStyle(DockWalkTheme.textSecondary)
                    .multilineTextAlignment(.center)
            } else {
                Text("No \(selectedStage.displayName.lowercased()) loads")
                    .font(DockWalkTheme.bodyFont)
                    .foregroundStyle(DockWalkTheme.textSecondary)
            }
        }
    }

    private func appointmentsForStage(_ stage: InboundStageFilter) -> [ReceivingAppointment] {
        viewModel.appointments.filter { $0.status == stage.status }
    }

    private func scheduledLoads(on day: Date) -> [ReceivingAppointment] {
        appointmentsForStage(.scheduled).filter { load in
            InboundWeekSchedule.isSameCalendarDay(load.scheduledAt, day, calendar: calendar)
        }
    }

    private func countForStageTab(_ stage: InboundStageFilter) -> Int {
        if stage == .scheduled {
            return scheduledLoads(on: selectedScheduleDay).count
        }
        return appointmentsForStage(stage).count
    }

    private func loadsForStage(_ stage: InboundStageFilter) -> [ReceivingAppointment] {
        let loads = appointmentsForStage(stage)
        guard stage == .scheduled else { return loads }
        return loads.filter { load in
            InboundWeekSchedule.isSameCalendarDay(load.scheduledAt, selectedScheduleDay, calendar: calendar)
        }
    }

    private func scheduleLabel(for load: ReceivingAppointment) -> String {
        if selectedStage == .scheduled {
            return load.scheduledAt.formatted(date: .omitted, time: .shortened)
        }
        return load.scheduledAt.formatted(date: .abbreviated, time: .shortened)
    }

    private func loadBinding(for load: ReceivingAppointment) -> Binding<ReceivingAppointment>? {
        Binding(
            get: {
                viewModel.appointments.first(where: { $0.id == load.id }) ?? load
            },
            set: { viewModel.updateLoad($0) }
        )
    }

    private func loadRow(_ load: ReceivingAppointment) -> some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(load.carrier)
                        .font(DockWalkTheme.headlineFont)
                        .foregroundStyle(DockWalkTheme.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(DockWalkTheme.textSecondary)
                }

                HStack(spacing: 12) {
                    Label(load.doorAssignmentLabel, systemImage: "door.left.hand.open")
                    Label(scheduleLabel(for: load), systemImage: "clock")
                }
                .font(DockWalkTheme.captionFont)
                .foregroundStyle(DockWalkTheme.textSecondary)

                HStack {
                    Text(load.poNumber)
                        .font(DockWalkTheme.captionFont)
                        .foregroundStyle(DockWalkTheme.textSecondary)
                    Spacer()
                    Text("\(load.palletCount) pallets")
                        .font(DockWalkTheme.captionFont)
                        .foregroundStyle(DockWalkTheme.textSecondary)
                }
            }
        }
    }

    @ViewBuilder
    private var statusBanner: some View {
        if let mode = viewModel.dataMode, viewModel.loadPhase == .loaded {
            VStack(spacing: 4) {
                HStack {
                    Text(apiModeLabel(mode))
                        .font(DockWalkTheme.captionFont)
                    Spacer()
                    if replayCoordinator.isReplaying {
                        StatusChip(label: "Syncing receive", tone: .info)
                    } else if !viewModel.apiReachable {
                        StatusChip(label: mode == "foundation" ? "API offline" : "Health offline", tone: .warning)
                    }
                }
                if mode == "foundation-demo" {
                    Text("Local demo queue (30 scheduled loads). Toggle in More → API connection. API may still be used for receive sync.")
                        .font(DockWalkTheme.captionFont)
                        .foregroundStyle(DockWalkTheme.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                if mode == "foundation" {
                    Text("Showing dev-seed preview data — Railway API host is unreachable. Redeploy dockwalk-api or update the base URL in More → API connection.")
                        .font(DockWalkTheme.captionFont)
                        .foregroundStyle(DockWalkTheme.warning)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                if syncStore.pendingReceivingEventCount > 0 {
                    Text("\(syncStore.pendingReceivingEventCount) receive event(s) queued")
                        .font(DockWalkTheme.captionFont)
                        .foregroundStyle(DockWalkTheme.warning)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.horizontal, DockWalkTheme.screenPadding)
            .padding(.vertical, 6)
            .background(DockWalkTheme.cardBackground)
        }
    }

    private func apiModeLabel(_ mode: String) -> String {
        switch mode {
        case "live": return "Live API"
        case "foundation-demo": return "Demo queue (30 loads)"
        case "foundation": return "Offline preview"
        default: return "API stub mode"
        }
    }
}

// MARK: - Stage Tab Button
private struct StageTabButton: View {
    let stage: InboundStageFilter
    let count: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(stage.displayName)
                    .font(.system(size: 15, weight: isSelected ? .semibold : .regular))
                Text("\(count)")
                    .font(.system(size: 13, weight: .medium))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? DockWalkTheme.accent : Color.clear)
            .foregroundStyle(isSelected ? .white : DockWalkTheme.textPrimary)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.clear : DockWalkTheme.textSecondary.opacity(0.2), lineWidth: 1)
            )
        }
    }
}

#Preview {
    AppointmentsView()
        .environment(AppEnvironment.shared)
        .environment(OfflineSyncStore.shared)
        .environment(SyncPreferencesStore.shared)
        .environment(ScannerPreferencesStore.shared)
        .environment(ReceivingEventReplayCoordinator.shared)
        .environment(DemoOperationalDataStore.shared)
        .environment(InboundSessionStore.shared)
        .environment(AppointmentsViewModel())
}
