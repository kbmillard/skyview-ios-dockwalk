import Foundation

enum InboundLineScanMatcher {
    static func normalize(_ code: String) -> String {
        code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    }

    /// Matches scanned code to line SKU (case-insensitive, trimmed).
    static func match(code: String, in lines: [InboundLineItem]) -> InboundLineItem? {
        let key = normalize(code)
        guard !key.isEmpty else { return nil }
        return lines.first { normalize($0.sku) == key }
    }
}
