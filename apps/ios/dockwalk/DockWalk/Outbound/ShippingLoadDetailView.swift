import SwiftUI

/// Shipping load work mode — scan staged product, confirm loaded items, complete shipment.
struct ShippingLoadDetailView: View {
    let order: OutboundOrder

    @Environment(ScannerPreferencesStore.self) private var scannerPreferences
    @State private var showScanConfirm = false
    @State private var showException = false
    @State private var showScanner = false

    private var shipmentId: String {
        order.orderNumber.hasPrefix("S-") ? order.orderNumber : order.orderNumber
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DockWalkTheme.sectionSpacing) {
                ScannerLockChip(mode: .shipment(shipmentId: shipmentId))

                loadHeader

                progressRow

                PrimaryActionButton(title: "Scan staged product", systemImage: "barcode.viewfinder") {
                    if scannerPreferences.isScannerActive {
                        showScanner = true
                    } else {
                        showScanConfirm = true
                    }
                }

                secondaryActions

                stagedLinesSection

                PrimaryActionButton(
                    title: "Complete shipment",
                    systemImage: "checkmark",
                    style: .secondary
                ) {}
            }
            .padding(DockWalkTheme.screenPadding)
        }
        .background(DockWalkTheme.background)
        .navigationTitle(shipmentId)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showScanConfirm) {
            ScanConfirmSheet(payload: ScanConfirmPayload.placeholder)
        }
        .sheet(isPresented: $showException) {
            ExceptionMarkingSheet()
        }
        .sheet(isPresented: $showScanner) {
            BarcodeScannerSheet(title: "Scan staged product") { _ in
                showScanConfirm = true
            }
        }
        .dismissScannerSheetWhenInactive(scannerPreferences, isPresented: $showScanner)
    }

    private var loadHeader: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 8) {
                detailRow("Customer", order.customer)
                detailRow("Carrier", "FedEx Freight")
                detailRow("Door", order.door.isEmpty ? "TBD" : order.door)
                HStack(spacing: 8) {
                    StatusChip(label: order.status.displayName, tone: order.status.chipTone)
                    if order.priority == .urgent {
                        StatusChip(label: "Hotshot", tone: .warning)
                    }
                }
            }
        }
    }

    private var progressRow: some View {
        SectionCard {
            HStack {
                Text("0 / \(order.cartonCount) items loaded")
                    .font(.system(.caption, design: .monospaced).weight(.semibold))
                Spacer()
                Text("0%")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(DockWalkTheme.textSecondary)
            }
        }
    }

    private var secondaryActions: some View {
        HStack(spacing: 8) {
            secondaryButton(title: "Shipment details", systemImage: "list.bullet") {}
            secondaryButton(title: "Mark missing", systemImage: "exclamationmark.triangle") {
                showException = true
            }
            secondaryButton(title: "Generate PO", systemImage: "doc") {}
        }
    }

    private var stagedLinesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Staged items · \(order.lineCount)")
                .font(DockWalkTheme.headlineFont)

            SectionCard {
                VStack(alignment: .leading, spacing: 10) {
                    lineRow(name: "Brake Rotor Assembly", codes: "SKU BR-8821 · Bin A-14", qty: "×8")
                    Divider()
                    lineRow(name: "Industrial Brake Pad", codes: "SKU BR-8825 · Bin A-15", qty: "×4")
                    Divider()
                    lineRow(name: "Hydraulic Hose ½″", codes: "SKU HH-3344 · Bin B-22", qty: "×2")
                }
            }
        }
    }

    private func detailRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label.uppercased())
                .font(.system(.caption2, design: .default).weight(.semibold))
                .foregroundStyle(DockWalkTheme.textSecondary)
            Spacer()
            Text(value)
                .font(DockWalkTheme.bodyFont.weight(.semibold))
        }
    }

    private func lineRow(name: String, codes: String, qty: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(DockWalkTheme.bodyFont.weight(.semibold))
                Text(codes)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(DockWalkTheme.textSecondary)
            }
            Spacer()
            Text(qty)
                .font(.system(.body, design: .monospaced).weight(.bold))
        }
    }

    private func secondaryButton(title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Image(systemName: systemImage)
                Text(title)
                    .font(.system(size: 10.5, weight: .semibold))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 11)
            .foregroundStyle(DockWalkTheme.textPrimary)
            .background(DockWalkTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        ShippingLoadDetailView(
            order: OutboundOrder(
                id: "out-ship",
                orderNumber: "S-55120",
                customer: "Midwest Supply",
                door: "Door 2",
                status: .staged,
                lineCount: 14,
                cartonCount: 14,
                priority: .urgent,
                shipDate: Date(),
                assignedTo: nil
            )
        )
    }
    .environment(ScannerPreferencesStore.shared)
}
