import AVFoundation
import SwiftUI

/// Feature-flagged scanner sandbox (`liveScannerEnabled`). Not a production workflow.
struct ScannerLabView: View {
    @State private var permission: CameraPermissionState = .notDetermined
    @State private var lastScan: ScanResult?
    @State private var manualCode = ""
    @State private var setupError: String?
    @State private var captureSession = BarcodeCaptureSession()
    @State private var isRunning = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DockWalkTheme.sectionSpacing) {
                Text("Scanner Lab uses the device camera for barcode and QR labels. Scans stay on-device — no upload or cloud AI.")
                    .font(DockWalkTheme.captionFont)
                    .foregroundStyle(DockWalkTheme.textSecondary)

                scannerArea

                if let lastScan {
                    ScanResultCard(result: lastScan) {
                        UIPasteboard.general.string = lastScan.value
                    }
                }

                manualEntrySection
            }
            .padding(DockWalkTheme.screenPadding)
        }
        .background(DockWalkTheme.background)
        .navigationTitle("Scanner Lab")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await refreshPermission()
        }
        .onDisappear {
            stopCamera()
        }
    }

    @ViewBuilder
    private var scannerArea: some View {
        ZStack {
            RoundedRectangle(cornerRadius: DockWalkTheme.cornerRadius, style: .continuous)
                .fill(Color.black.opacity(0.85))

            switch permission {
            case .authorized where BarcodeCaptureCoordinator.isCameraAvailable:
                BarcodeScannerPreviewView(captureSession: captureSession)
                    .clipShape(RoundedRectangle(cornerRadius: DockWalkTheme.cornerRadius, style: .continuous))
                scanReticle
            case .notDetermined:
                ProgressView("Checking camera…")
                    .tint(.white)
            case .denied, .restricted:
                permissionDeniedContent
            case .unavailable:
                simulatorFallbackContent
            case .authorized:
                simulatorFallbackContent
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 300)
        .overlay(alignment: .bottom) {
            if let setupError {
                Text(setupError)
                    .font(DockWalkTheme.captionFont)
                    .foregroundStyle(.white)
                    .padding(8)
                    .frame(maxWidth: .infinity)
                    .background(Color.red.opacity(0.75))
            }
        }
    }

    private var scanReticle: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .stroke(DockWalkTheme.accent, lineWidth: 3)
            .frame(width: 240, height: 140)
            .shadow(color: .black.opacity(0.35), radius: 4)
    }

    private var permissionDeniedContent: some View {
        VStack(spacing: 12) {
            Image(systemName: "camera.fill")
                .font(.largeTitle)
                .foregroundStyle(.white.opacity(0.8))
            Text("Camera access denied")
                .font(DockWalkTheme.headlineFont)
                .foregroundStyle(.white)
            Text("Enable camera for DockWalk in Settings to scan labels.")
                .font(DockWalkTheme.captionFont)
                .foregroundStyle(.white.opacity(0.85))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    private var simulatorFallbackContent: some View {
        VStack(spacing: 12) {
            Image(systemName: "barcode.viewfinder")
                .font(.system(size: 48))
                .foregroundStyle(DockWalkTheme.accent)
            Text("Camera not available")
                .font(DockWalkTheme.headlineFont)
                .foregroundStyle(.white)
            Text("Use manual entry below on Simulator or when no camera is present.")
                .font(DockWalkTheme.captionFont)
                .foregroundStyle(.white.opacity(0.85))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
    }

    private var manualEntrySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Manual entry")
                .font(DockWalkTheme.headlineFont)
            TextField("Enter barcode or label code", text: $manualCode)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .font(.system(.body, design: .monospaced))
                .padding(12)
                .background(DockWalkTheme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            PrimaryActionButton(title: "Submit code", systemImage: "keyboard") {
                submitManual()
            }
            .disabled(manualCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }

    private func refreshPermission() async {
        permission = await BarcodeCaptureCoordinator.requestPermission()
        setupError = nil
        guard permission == .authorized, BarcodeCaptureCoordinator.isCameraAvailable else { return }
        captureSession.onCodeDetected = { result in
            lastScan = result
        }
        do {
            try captureSession.configureIfNeeded()
            startCamera()
        } catch {
            setupError = error.localizedDescription
            stopCamera()
        }
    }

    private func startCamera() {
        guard !isRunning else { return }
        captureSession.start()
        isRunning = true
    }

    private func stopCamera() {
        guard isRunning else { return }
        captureSession.stop()
        isRunning = false
    }

    private func submitManual() {
        captureSession.deliverManualEntry(manualCode)
        if let lastScan {
            manualCode = lastScan.value
        }
    }
}

#Preview {
    NavigationStack {
        ScannerLabView()
    }
}
