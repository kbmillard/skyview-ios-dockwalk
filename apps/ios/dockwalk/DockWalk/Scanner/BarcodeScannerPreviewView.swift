import AVFoundation
import SwiftUI

struct BarcodeScannerPreviewView: UIViewRepresentable {
    let captureSession: BarcodeCaptureSession

    func makeUIView(context: Context) -> ScannerPreviewUIView {
        let view = ScannerPreviewUIView()
        view.previewLayer = captureSession.makePreviewLayer()
        return view
    }

    func updateUIView(_ uiView: ScannerPreviewUIView, context: Context) {
        uiView.previewLayer?.frame = uiView.bounds
    }
}

final class ScannerPreviewUIView: UIView {
    var previewLayer: AVCaptureVideoPreviewLayer? {
        didSet {
            oldValue?.removeFromSuperlayer()
            if let previewLayer {
                previewLayer.frame = bounds
                layer.addSublayer(previewLayer)
            }
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer?.frame = bounds
    }
}
