import SwiftUI

struct AppointmentsView: View {
    @State private var viewModel = AppointmentsViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.appointments.isEmpty {
                    ContentUnavailableView(
                        "No appointments",
                        systemImage: "calendar",
                        description: Text("Inbound appointments will appear here.")
                    )
                } else {
                    List(viewModel.appointments) { appointment in
                        NavigationLink {
                            ReceivingView(appointment: appointment)
                        } label: {
                            appointmentRow(appointment)
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Receive")
            .refreshable {
                await viewModel.refresh()
            }
            .overlay(alignment: .top) {
                if !viewModel.apiReachable {
                    apiBanner
                }
            }
        }
        .task {
            await viewModel.refresh()
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

    private var apiBanner: some View {
        Text("API offline — showing stub appointments")
            .font(DockWalkTheme.captionFont)
            .frame(maxWidth: .infinity)
            .padding(8)
            .background(DockWalkTheme.warning.opacity(0.15))
    }
}

#Preview {
    AppointmentsView()
}
