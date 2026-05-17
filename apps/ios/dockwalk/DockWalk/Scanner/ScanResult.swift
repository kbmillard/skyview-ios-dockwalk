import Foundation

struct ScanResult: Identifiable, Equatable {
    let id: UUID
    let symbology: String
    let value: String
    let scannedAt: Date

    init(symbology: String = "Code128", value: String, scannedAt: Date = .now) {
        self.id = UUID()
        self.symbology = symbology
        self.value = value
        self.scannedAt = scannedAt
    }
}
