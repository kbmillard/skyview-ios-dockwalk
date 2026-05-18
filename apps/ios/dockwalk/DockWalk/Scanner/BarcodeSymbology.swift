import AVFoundation

enum BarcodeSymbology {
    static let supportedMetadataTypes: [AVMetadataObject.ObjectType] = [
        .qr,
        .code128,
        .code39,
        .ean13,
        .ean8,
        .upce,
        .pdf417,
    ]

    static func displayName(for type: AVMetadataObject.ObjectType) -> String {
        switch type {
        case .qr: return "QR"
        case .code128: return "Code 128"
        case .code39: return "Code 39"
        case .ean13: return "EAN-13"
        case .ean8: return "EAN-8"
        case .upce: return "UPC-E"
        case .pdf417: return "PDF417"
        default: return type.rawValue
        }
    }

    static func displayName(forRaw raw: String) -> String {
        raw.isEmpty ? "Unknown" : raw
    }
}
