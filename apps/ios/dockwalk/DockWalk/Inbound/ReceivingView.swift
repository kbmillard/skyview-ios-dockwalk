import SwiftUI

struct ReceivingView: View {
    @Environment(AppEnvironment.self) private var environment
    @Bindable var viewModel: ReceivingViewModel
    @State private var showScanner = false
    @Environment(OfflineSyncStore.self) private var syncStore
    @Environment(ScannerPreferencesStore.self) private var scannerPreferences

    init(appointment: ReceivingAppointment, environment: AppEnvironment = .shared) {
        viewModel = ReceivingViewModel(appointment: appointment, environment: environment)
    }

    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DockWalkTheme.sectionSpacing) {
                    Text("Open an inbound shipment below to view lines and record receive quantities.")
                        .font(DockWalkTheme.captionFont)
                        .foregroundStyle(DockWalkTheme.textSecondary)
                    summaryCard
                    actionButtons

                    switch viewModel.loadPhase {
                    case .loaded, .loading:
                        shipmentsSection
                    case .empty, .error:
                        LoadStateView(phase: viewModel.loadPhase) {
                            Task { await viewModel.load() }
                        }
                        .frame(minHeight: 200)
                    case .idle:
                        EmptyView()
                    }

                    scannerNote
                }
                .padding(DockWalkTheme.screenPadding)
            }

            if viewModel.loadPhase == .loading {
                LoadStateView(phase: .loading)
                    .background(.ultraThinMaterial)
            }
        }
        .background(DockWalkTheme.background)
        .navigationTitle("Receiving")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showScanner) {
            ScannerLabView()
        }
        .dismissScannerSheetWhenInactive(scannerPreferences, isPresented: $showScanner)
        .task(id: environment.configRevision) {
            await viewModel.load()
        }
    }

    private var summaryCard: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 8) {
                Text(viewModel.appointment.carrier)
                    .font(DockWalkTheme.headlineFont)
                Label(viewModel.appointment.dock, systemImage: "door.left.hand.open")
                Label(viewModel.appointment.poNumber, systemImage: "doc.text")
                Label("\(viewModel.appointment.palletCount) pallets", systemImage: "square.stack.3d.up")
                StatusChip(label: viewModel.appointment.status.displayName, tone: viewModel.appointment.status.chipTone)
                if let mode = viewModel.dataMode {
                    StatusChip(label: mode == "live" ? "Live shipments" : "Stub API", tone: .neutral)
                }
            }
            .font(DockWalkTheme.bodyFont)
            .foregroundStyle(DockWalkTheme.textSecondary)
        }
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            if scannerPreferences.isScannerActive {
                PrimaryActionButton(title: "Scan", systemImage: "barcode.viewfinder") {
                    showScanner = true
                }
            }
            PrimaryActionButton(
                title: viewModel.isReceiving ? "Receiving in progress" : "Start Receiving",
                systemImage: "play.fill",
                style: viewModel.isReceiving ? .secondary : .primary
            ) {
                viewModel.startReceiving()
                syncStore.enqueue(kind: "inbound.start", summary: viewModel.appointment.poNumber)
            }
            PrimaryActionButton(title: "Add Exception", systemImage: "exclamationmark.triangle", style: .secondary) {
                syncStore.enqueue(kind: "exception", summary: "Receiving exception — \(viewModel.appointment.poNumber)")
            }
        }
    }

    private var shipmentsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Inbound shipments")
                .font(DockWalkTheme.headlineFont)

            if viewModel.shipments.isEmpty && viewModel.loadPhase != .loading {
                Text("No shipments for this appointment.")
                    .foregroundStyle(DockWalkTheme.textSecondary)
            } else {
                ForEach(viewModel.shipments) { shipment in
                    NavigationLink {
                        ShipmentDetailView(
                            shipment: shipment,
                            appointmentId: viewModel.appointment.id,
                            environment: environment
                        )
                    } label: {
                        shipmentRow(shipment)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func shipmentRow(_ shipment: InboundShipmentItem) -> some View {
        SectionCard {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(shipment.referenceNumber)
                        .font(DockWalkTheme.headlineFont)
                    Text("Tap to view lines and record receive")
                        .font(DockWalkTheme.captionFont)
                        .foregroundStyle(DockWalkTheme.textSecondary)
                }
                Spacer()
                StatusChip(label: shipment.statusDisplay, tone: .info)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(DockWalkTheme.textSecondary)
            }
        }
    }

    @ViewBuilder
    private var scannerNote: some View {
        if !scannerPreferences.isScannerActive {
            Text("Shipments load from GET /api/inbound/shipments; lines and receive use the live inbound routes.")
                .font(DockWalkTheme.captionFont)
                .foregroundStyle(DockWalkTheme.textSecondary)
                .padding(.top, 8)
        }
    }
}

#Preview {
    NavigationStack {
        ReceivingView(
            appointment: ReceivingAppointment(
                id: "preview",
                carrier: "Preview Carrier",
                dock: "Dock 2",
                scheduledAt: .now,
                status: .scheduled,
                poNumber: "PO-000",
                palletCount: 10
            )
        )
    }
    .environment(AppEnvironment.shared)
    .environment(OfflineSyncStore.shared)
}
