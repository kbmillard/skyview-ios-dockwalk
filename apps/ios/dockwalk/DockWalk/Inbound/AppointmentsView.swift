import SwiftUI

struct AppointmentsView: View {
    @Environment(AppEnvironment.self) private var environment
    @Environment(OfflineSyncStore.self) private var syncStore
    @Environment(ReceivingEventReplayCoordinator.self) private var replayCoordinator
    @State private var viewModel: AppointmentsViewModel?

    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel?.loadPhase == .loaded {
                    appointmentsList
                } else if let viewModel {
                    LoadStateView(phase: viewModel.loadPhase) {
                        Task { await viewModel.refresh() }
                    }
                }

                if case .loading? = viewModel?.loadPhase {
                    LoadStateView(phase: .loading)
                        .background(.ultraThinMaterial)
                }
            }
            .navigationTitle("Receive")
            .refreshable {
                await viewModel?.refresh(syncStore: syncStore)
            }
            .safeAreaInset(edge: .top) {
                statusBanner
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = AppointmentsViewModel(environment: environment)
            }
        }
        .task(id: environment.configRevision) {
            if viewModel == nil {
                viewModel = AppointmentsViewModel(environment: environment)
            }
            await viewModel?.refresh(syncStore: syncStore)
        }
    }

    @ViewBuilder
    private var appointmentsList: some View {
        if let viewModel {
            List(viewModel.appointments) { appointment in
                NavigationLink {
                    ReceivingView(appointment: appointment, environment: environment)
                } label: {
                    appointmentRow(appointment)
                }
            }
            .listStyle(.insetGrouped)
        }
    }

    private func appointmentRow(_ appointment: ReceivingAppointment) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(appointment.carrier)
                    .font(DockWalkTheme.headlineFont)
                Spacer()
                StatusChip(label: appointment.status.displayName, tone: appointment.status.chipTone)
            }
            HStack(spacing: 12) {
                Label(appointment.dock, systemImage: "door.left.hand.open")
                Label(appointment.scheduledAt.formatted(date: .omitted, time: .shortened), systemImage: "clock")
            }
            .font(DockWalkTheme.captionFont)
            .foregroundStyle(DockWalkTheme.textSecondary)
            Text(appointment.poNumber)
                .font(DockWalkTheme.captionFont)
                .foregroundStyle(DockWalkTheme.textSecondary)
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var statusBanner: some View {
        if let viewModel, let mode = viewModel.dataMode, viewModel.loadPhase == .loaded {
            VStack(spacing: 4) {
                HStack {
                    Text(mode == "live" ? "Live API" : "API stub mode")
                        .font(DockWalkTheme.captionFont)
                    Spacer()
                    if replayCoordinator.isReplaying {
                        StatusChip(label: "Syncing receive", tone: .info)
                    } else if !viewModel.apiReachable {
                        StatusChip(label: "Health offline", tone: .warning)
                    }
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
}

#Preview {
    AppointmentsView()
        .environment(AppEnvironment.shared)
        .environment(OfflineSyncStore.shared)
        .environment(SyncPreferencesStore.shared)
        .environment(ScannerPreferencesStore.shared)
        .environment(ReceivingEventReplayCoordinator.shared)
}
