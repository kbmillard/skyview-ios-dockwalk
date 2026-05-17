import SwiftUI

struct ReceivingView: View {
    @State private var viewModel: ReceivingViewModel
    @State private var showScanner = false
    @Environment(OfflineSyncStore.self) private var syncStore

    init(appointment: ReceivingAppointment) {
        _viewModel = State(initialValue: ReceivingViewModel(appointment: appointment))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DockWalkTheme.sectionSpacing) {
                summaryCard
                actionButtons
                receivedLinesSection
                stubNote
            }
            .padding(DockWalkTheme.screenPadding)
        }
        .background(DockWalkTheme.background)
        .navigationTitle("Receiving")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showScanner) {
            ScannerPlaceholderView()
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
            }
            .font(DockWalkTheme.bodyFont)
            .foregroundStyle(DockWalkTheme.textSecondary)
        }
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            PrimaryActionButton(title: "Scan", systemImage: "barcode.viewfinder") {
                showScanner = true
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

    private var receivedLinesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Received lines")
                .font(DockWalkTheme.headlineFont)
            if viewModel.receivedLines.isEmpty {
                Text("No lines yet — scan or enter manually (stub).")
                    .foregroundStyle(DockWalkTheme.textSecondary)
            } else {
                ForEach(viewModel.receivedLines) { line in
                    SectionCard {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(line.sku)
                                    .font(.system(.body, design: .monospaced).weight(.semibold))
                                Text(line.description)
                                    .font(DockWalkTheme.captionFont)
                                    .foregroundStyle(DockWalkTheme.textSecondary)
                            }
                            Spacer()
                            Text("×\(line.quantity)")
                                .font(DockWalkTheme.headlineFont)
                        }
                    }
                }
            }
        }
    }

    private var stubNote: some View {
        Text("Scanner and DockWalk API are stubbed in this foundation build. Live AVFoundation scanning and inbound sync ship in a later phase.")
            .font(DockWalkTheme.captionFont)
            .foregroundStyle(DockWalkTheme.textSecondary)
            .padding(.top, 8)
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
    .environment(OfflineSyncStore.shared)
}
