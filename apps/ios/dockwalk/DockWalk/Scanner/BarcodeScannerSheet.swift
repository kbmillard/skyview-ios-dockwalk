import SwiftUI

/// Reusable scanner sheet; uses the same capture + manual path as Scanner Lab.
struct BarcodeScannerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(ScannerPreferencesStore.self) private var scannerPreferences

    let title: String
    var applyStyle: ScannerApplyStyle = .confirm
    var applyButtonTitle: String = "Use this code"
    var manualEntryPlaceholder: String = "Barcode"
    let onScan: (ScanResult) -> Void

    @State private var permission: CameraPermissionState = .notDetermined
    @State private var lastScan: ScanResult?
    @State private var manualCode = ""
    @State private var setupError: String?
    @State private var captureSession = BarcodeCaptureSession()
    @State private var isRunning = false

    private var resolvedCode: String {
        let manual = manualCode.trimmingCharacters(in: .whitespacesAndNewlines)
        if !manual.isEmpty { return manual }
        return lastScan?.value.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DockWalkTheme.sectionSpacing) {
                    scannerBlock
                    switch applyStyle {
                    case .confirm:
                        confirmApplySection
                    case .direct:
                        directApplySection
                    }
                }
                .padding(DockWalkTheme.screenPadding)
            }
            .background(DockWalkTheme.background)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .task { await refreshPermission() }
            .onDisappear { stopCamera() }
            .exitIfScannerInactive(scannerPreferences)
        }
    }

    @ViewBuilder
    private var confirmApplySection: some View {
        if let lastScan {
            ScanResultCard(result: lastScan)
            PrimaryActionButton(title: applyButtonTitle, systemImage: "checkmark.circle.fill") {
                onScan(lastScan)
                dismiss()
            }
        }
        confirmManualEntrySection
    }

    @ViewBuilder
    private var directApplySection: some View {
        directManualEntrySection
        if !resolvedCode.isEmpty {
            Text(resolvedCode)
                .font(.system(.body, design: .monospaced).weight(.semibold))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 4)
        }
        PrimaryActionButton(title: applyButtonTitle, systemImage: "checkmark.circle.fill") {
            applyResolvedCode()
        }
        .disabled(resolvedCode.isEmpty)
    }

    @ViewBuilder
    private var scannerBlock: some View {
        ZStack {
            RoundedRectangle(cornerRadius: DockWalkTheme.cornerRadius, style: .continuous)
                .fill(Color.black.opacity(0.85))
            switch permission {
            case .authorized where BarcodeCaptureCoordinator.isCameraAvailable:
                BarcodeScannerPreviewView(captureSession: captureSession)
                    .clipShape(RoundedRectangle(cornerRadius: DockWalkTheme.cornerRadius, style: .continuous))
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(DockWalkTheme.accent, lineWidth: 3)
                    .frame(width: 220, height: 120)
            case .denied, .restricted:
                Text("Camera denied — use manual entry.")
                    .font(DockWalkTheme.captionFont)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding()
            default:
                Text("Camera unavailable — use manual entry.")
                    .font(DockWalkTheme.captionFont)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding()
            }
        }
        .frame(height: 260)
        .overlay(alignment: .bottom) {
            if let setupError {
                Text(setupError)
                    .font(.caption2)
                    .foregroundStyle(.white)
                    .padding(6)
                    .frame(maxWidth: .infinity)
                    .background(Color.red.opacity(0.75))
            }
        }
    }

    private var confirmManualEntrySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Enter code manually")
                .font(DockWalkTheme.headlineFont)
            CursorAtEndTextField(
                placeholder: manualEntryPlaceholder,
                text: $manualCode,
                autocapitalizationType: .allCharacters,
                textAlignment: .natural
            )
            .font(.system(.body, design: .monospaced))
            .padding(12)
            .background(DockWalkTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            PrimaryActionButton(title: "Submit", systemImage: "keyboard", style: .secondary) {
                captureSession.deliverManualEntry(manualCode)
            }
            .disabled(manualCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }

    private var directManualEntrySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Enter code manually")
                .font(DockWalkTheme.headlineFont)
            CursorAtEndTextField(
                placeholder: manualEntryPlaceholder,
                text: $manualCode,
                autocapitalizationType: .allCharacters,
                textAlignment: .natural
            )
            .font(.system(.body, design: .monospaced))
            .padding(12)
            .background(DockWalkTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .onChange(of: manualCode) { _, _ in
                syncManualToLastScan()
            }
        }
    }

    private func syncManualToLastScan() {
        let trimmed = manualCode.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        lastScan = ScanResult(symbology: "Manual", value: trimmed)
    }

    private func applyResolvedCode() {
        let code = resolvedCode
        guard !code.isEmpty else { return }
        let result = lastScan ?? ScanResult(symbology: "Manual", value: code)
        onScan(result)
        dismiss()
    }

    private func refreshPermission() async {
        permission = await BarcodeCaptureCoordinator.requestPermission()
        captureSession.onCodeDetected = { result in
            lastScan = result
            if applyStyle == .direct {
                manualCode = result.value
            }
        }
        guard permission == .authorized, BarcodeCaptureCoordinator.isCameraAvailable else { return }
        do {
            try captureSession.configureIfNeeded()
            startCamera()
        } catch {
            setupError = error.localizedDescription
        }
    }

    private func startCamera() {
        guard !isRunning else { return }
        captureSession.start()
        isRunning = true
    }

    private func stopCamera() {
        captureSession.stop()
        isRunning = false
    }
}
