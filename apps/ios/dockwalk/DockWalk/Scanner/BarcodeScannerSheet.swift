import SwiftUI

/// Reusable scanner sheet; uses the same capture + manual path as Scanner Lab.
struct BarcodeScannerSheet: View {
    @Environment(\.dismiss) private var dismiss

    let title: String
    let onScan: (ScanResult) -> Void

    @State private var permission: CameraPermissionState = .notDetermined
    @State private var lastScan: ScanResult?
    @State private var manualCode = ""
    @State private var setupError: String?
    @State private var captureSession = BarcodeCaptureSession()
    @State private var isRunning = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DockWalkTheme.sectionSpacing) {
                    scannerBlock
                    if let lastScan {
                        ScanResultCard(result: lastScan)
                        PrimaryActionButton(title: "Use this code", systemImage: "checkmark.circle.fill") {
                            onScan(lastScan)
                            dismiss()
                        }
                    }
                    manualEntrySection
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
        }
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

    private var manualEntrySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Enter code manually")
                .font(DockWalkTheme.headlineFont)
            TextField("Barcode", text: $manualCode)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
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

    private func refreshPermission() async {
        permission = await BarcodeCaptureCoordinator.requestPermission()
        captureSession.onCodeDetected = { result in
            lastScan = result
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
