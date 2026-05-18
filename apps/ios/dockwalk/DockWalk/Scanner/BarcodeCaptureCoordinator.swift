import AVFoundation
import Foundation

enum CameraPermissionState: Equatable {
    case notDetermined
    case authorized
    case denied
    case restricted
    case unavailable
}

enum BarcodeCaptureCoordinator {
    static func currentPermissionState() -> CameraPermissionState {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: return .authorized
        case .denied: return .denied
        case .restricted: return .restricted
        case .notDetermined: return .notDetermined
        @unknown default: return .restricted
        }
    }

    static func requestPermission() async -> CameraPermissionState {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        if status == .notDetermined {
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            return granted ? .authorized : .denied
        }
        return currentPermissionState()
    }

    static var isCameraAvailable: Bool {
        #if targetEnvironment(simulator)
        return false
        #else
        return AVCaptureDevice.default(for: .video) != nil
        #endif
    }
}

/// Owns `AVCaptureSession` on a dedicated queue; delivers codes on the main queue.
final class BarcodeCaptureSession: NSObject {
    private let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "io.skyprairie.dockwalk.barcode.session")
    private let metadataOutput = AVCaptureMetadataOutput()

    private(set) var previewLayer: AVCaptureVideoPreviewLayer?

    var onCodeDetected: ((ScanResult) -> Void)?

    private var deduplicator = BarcodeScanDeduplicator()
    private var isConfigured = false

    func makePreviewLayer() -> AVCaptureVideoPreviewLayer {
        if let previewLayer {
            return previewLayer
        }
        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        previewLayer = layer
        return layer
    }

    func configureIfNeeded() throws {
        guard !isConfigured else { return }
        guard BarcodeCaptureCoordinator.isCameraAvailable else {
            throw BarcodeCaptureError.cameraUnavailable
        }
        guard BarcodeCaptureCoordinator.currentPermissionState() == .authorized else {
            throw BarcodeCaptureError.notAuthorized
        }

        session.beginConfiguration()
        defer { session.commitConfiguration() }

        session.sessionPreset = .high

        guard let device = AVCaptureDevice.default(for: .video) else {
            throw BarcodeCaptureError.cameraUnavailable
        }
        let input = try AVCaptureDeviceInput(device: device)
        guard session.canAddInput(input) else {
            throw BarcodeCaptureError.configurationFailed
        }
        session.addInput(input)

        guard session.canAddOutput(metadataOutput) else {
            throw BarcodeCaptureError.configurationFailed
        }
        session.addOutput(metadataOutput)
        metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        metadataOutput.metadataObjectTypes = BarcodeSymbology.supportedMetadataTypes

        isConfigured = true
    }

    func start() {
        sessionQueue.async { [weak self] in
            guard let self, !self.session.isRunning else { return }
            self.session.startRunning()
        }
    }

    func stop() {
        sessionQueue.async { [weak self] in
            guard let self, self.session.isRunning else { return }
            self.session.stopRunning()
        }
    }

    func resetDedup() {
        deduplicator.reset()
    }

    func deliverManualEntry(_ value: String) {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let result = ScanResult(symbology: "Manual", value: trimmed)
        onCodeDetected?(result)
    }

    private func deliverDetected(value: String, symbology: String) {
        guard deduplicator.shouldAccept(value: value) else { return }
        let result = ScanResult(symbology: symbology, value: value.trimmingCharacters(in: .whitespacesAndNewlines))
        onCodeDetected?(result)
    }
}

extension BarcodeCaptureSession: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        guard let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let value = object.stringValue else { return }
        let name = BarcodeSymbology.displayName(for: object.type)
        deliverDetected(value: value, symbology: name)
    }
}

enum BarcodeCaptureError: LocalizedError {
    case notAuthorized
    case cameraUnavailable
    case configurationFailed

    var errorDescription: String? {
        switch self {
        case .notAuthorized: return "Camera access is required to scan labels."
        case .cameraUnavailable: return "No camera is available on this device."
        case .configurationFailed: return "Could not start the camera scanner."
        }
    }
}
