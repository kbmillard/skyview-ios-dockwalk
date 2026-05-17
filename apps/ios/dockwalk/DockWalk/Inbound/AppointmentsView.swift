import SwiftUI

struct AppointmentsView: View {
    @State private var viewModel = AppointmentsViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.loadPhase == .loaded {
                    appointmentsList
                } else {
                    LoadStateView(phase: viewModel.loadPhase) {
                        Task { await viewModel.refresh() }
                    }
                }

                if viewModel.loadPhase == .loading {
                    LoadStateView(phase: .loading)
                        .background(.ultraThinMaterial)
                }
            }
            .navigationTitle("Receive")
            .refreshable {
                await viewModel.refresh()
            }
            .safeAreaInset(edge: .top) {
                statusBanner
            }
        }
        .task {
            if viewModel.loadPhase == .idle {
                await viewModel.refresh()
            }
        }
    }

    @ViewBuilder
    private var appointmentsList: some View {
        List(viewModel.appointments) { appointment in
            NavigationLink {
                ReceivingView(appointment: appointment)
            } label: {
                appointmentRow(appointment)
            }
        }
        .listStyle(.insetGrouped)
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
        if let mode = viewModel.dataMode, viewModel.loadPhase == .loaded {
            HStack {
                Text(mode == "live" ? "Live API" : "API stub mode")
                    .font(DockWalkTheme.captionFont)
                Spacer()
                if !viewModel.apiReachable {
                    StatusChip(label: "Health offline", tone: .warning)
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
}
