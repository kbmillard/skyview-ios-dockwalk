import Foundation

struct PickTask: Identifiable, Codable, Equatable {
    let id: String
    let shipmentId: String
    let orderNumber: String
    let customer: String
    var status: PickTaskStatus
    let priority: PickPriority
    let dueDate: Date?
    var lines: [PickLine]
    var assignedTo: String?
    let createdAt: Date
    var updatedAt: Date
}

struct PickLine: Identifiable, Codable, Equatable {
    let id: String
    let taskId: String
    let sku: String
    let upc: String?
    let partNumber: String?
    let itemName: String
    let description: String
    let fromLocation: String
    var quantityOrdered: Int
    var quantityPicked: Int
    var status: PickLineStatus
    var scannedAt: Date?
}

enum PickTaskStatus: String, Codable, CaseIterable {
    case readyToPick = "Ready to Pick"
    case assigned = "Assigned"
    case picking = "Picking"
    case picked = "Picked"
    case staged = "Staged"
    case blocked = "Blocked"
    case complete = "Complete"
    case cancelled = "Cancelled"
}

enum PickLineStatus: String, Codable, CaseIterable {
    case pending = "Pending"
    case picking = "Picking"
    case picked = "Picked"
    case short = "Short"
    case damaged = "Damaged"
    case notFound = "Not Found"
}

enum PickPriority: String, Codable, CaseIterable {
    case standard = "Standard"
    case expedited = "Expedited"
    case rush = "Rush"
}

struct PickTaskSummary {
    let readyToPickCount: Int
    let assignedCount: Int
    let pickingCount: Int
    let pickedCount: Int
    let blockedCount: Int
    let totalLines: Int
    let totalQuantity: Int
}
