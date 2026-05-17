import SwiftUI

struct ShipmentDetailView: View {
    @Environment(AppEnvironment.self) private var environment
    @Environment(OfflineSyncStore.self) private var syncStore
    @Bindable var viewModel: ShipmentDetailViewModel

    init(shipment: InboundShipmentItem, appointmentId: String?, environment: AppEnvironment = .shared) {
        viewModel = ShipmentDetailViewModel(
            shipment: shipment,
            appointmentId: appointmentId,
            environment: environment
        )
    }

    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DockWalkTheme.sectionSpacing) {
                    shipmentHeader
                    submitSection
                    linesSection
                }
                .padding(DockWalkTheme.screenPadding)
            }

            if viewModel.loadPhase == .loading {
                LoadStateView(phase: .loading)
                    .background(.ultraThinMaterial)
            }
        }
        .background(DockWalkTheme.background)
        .navigationTitle(viewModel.shipment.referenceNumber)
        .navigationBarTitleDisplayMode(.inline)
        .task(id: environment.configRevision) {
            await viewModel.load()
        }
    }

    private var shipmentHeader: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 8) {
                Text(viewModel.shipment.referenceNumber)
                    .font(DockWalkTheme.headlineFont)
                StatusChip(label: viewModel.shipment.statusDisplay, tone: .info)
                if let mode = viewModel.dataMode {
                    StatusChip(label: mode == "live" ? "Live lines" : "Stub API", tone: .neutral)
                }
            }
        }
    }

    private var submitSection: some View {
        VStack(spacing: 12) {
            PrimaryActionButton(
                title: "Fill remaining qty",
                systemImage: "arrow.down.to.line",
                style: .secondary
            ) {
                viewModel.setReceiveAllRemaining()
            }

            PrimaryActionButton(
                title: viewModel.isSubmitting && viewModel.receivingLineId == nil
                    ? "Submitting…"
                    : "Record custom quantities",
                systemImage: "checkmark.circle.fill",
                style: .secondary
            ) {
                Task { await viewModel.submitReceive() }
            }
            .disabled(viewModel.isSubmitting || viewModel.loadPhase != .loaded)

            submitResultBanner

            if syncStore.pendingReceivingEventCount > 0 {
                Text("\(syncStore.pendingReceivingEventCount) receiving event(s) queued offline.")
                    .font(DockWalkTheme.captionFont)
                    .foregroundStyle(DockWalkTheme.warning)
            }
        }
    }

    @ViewBuilder
    private var submitResultBanner: some View {
        switch viewModel.lastSubmitResult {
        case .success(let idempotent, let mode, _):
            StatusChip(
                label: idempotent ? "Already recorded (\(mode))" : "Receive recorded (\(mode))",
                tone: .success
            )
        case .queuedOffline:
            VStack(alignment: .leading, spacing: 6) {
                StatusChip(label: "Queued offline", tone: .warning)
                Text("Saved locally with the same idempotency key. Replay from Debug or enable auto-replay in Sync.")
                    .font(DockWalkTheme.captionFont)
                    .foregroundStyle(DockWalkTheme.textSecondary)
            }
        case .failure(let message):
            Text(message)
                .font(DockWalkTheme.captionFont)
                .foregroundStyle(DockWalkTheme.danger)
        case nil:
            EmptyView()
        }
    }

    @ViewBuilder
    private var linesSection: some View {
        switch viewModel.loadPhase {
        case .loaded:
            VStack(alignment: .leading, spacing: 12) {
                Text("Lines")
                    .font(DockWalkTheme.headlineFont)
                ForEach(viewModel.lines) { line in
                    InboundLineRowView(
                        line: line,
                        isReceiving: viewModel.isSubmitting && viewModel.receivingLineId == line.id
                    ) {
                        Task { await viewModel.receiveOne(lineId: line.id) }
                    }
                }
            }
        case .empty, .error:
            LoadStateView(phase: viewModel.loadPhase) {
                Task { await viewModel.load() }
            }
            .frame(minHeight: 160)
        case .idle, .loading:
            EmptyView()
        }
    }
}

#Preview {
    NavigationStack {
        ShipmentDetailView(
            shipment: InboundShipmentItem(
                id: "ship-1",
                appointmentId: "apt-1",
                referenceNumber: "ASN-100",
                status: "receiving",
                expectedAt: nil,
                receivedAt: nil
            ),
            appointmentId: "apt-1"
        )
    }
    .environment(AppEnvironment.shared)
    .environment(OfflineSyncStore.shared)
}
