import Foundation

/// Dev-seed-aligned preview data when the DockWalk API host is unreachable.
/// UUIDs match `skyview-dockwalk/supabase/seed/dev_org_seed.sql`.
enum FoundationOperationalData {
    static let receivingAppointments: [ReceivingAppointment] = [
        ReceivingAppointment(
            id: "00000000-0000-4000-8000-000000000101",
            carrier: "Swift Freight",
            dock: "Door 1",
            scheduledAt: Date().addingTimeInterval(2 * 3600),
            status: .scheduled,
            poNumber: "APT-1001",
            palletCount: 12
        ),
        ReceivingAppointment(
            id: "00000000-0000-4000-8000-000000000102",
            carrier: "JB Hunt",
            dock: "Door 1",
            scheduledAt: Date().addingTimeInterval(-30 * 60),
            status: .checkedIn,
            poNumber: "APT-1002",
            palletCount: 8
        ),
    ]

    static let putawayTasks: [PutawayTaskItem] = [
        PutawayTaskItem(
            id: "00000000-0000-4000-8000-000000000501",
            sku: "SKU-DEV-001",
            description: "Put away received widgets A",
            quantity: 10,
            uom: "ea",
            status: .pending,
            fromLocationCode: "RECV-STAGE",
            toLocationCode: "BIN-A-01",
            inboundShipmentId: "00000000-0000-4000-8000-000000000201",
            createdAt: nil
        ),
        PutawayTaskItem(
            id: "00000000-0000-4000-8000-000000000502",
            sku: "SKU-DEV-002",
            description: "Put away received widgets B",
            quantity: 5,
            uom: "ea",
            status: .pending,
            fromLocationCode: "RECV-STAGE",
            toLocationCode: "BIN-A-01",
            inboundShipmentId: "00000000-0000-4000-8000-000000000201",
            createdAt: nil
        ),
    ]

    static func putawayTasks(
        filteredBy inboundShipmentId: String?,
        status: PutawayTaskStatusFilter
    ) -> [PutawayTaskItem] {
        var items = putawayTasks
        if let inboundShipmentId {
            items = items.filter { $0.inboundShipmentId == inboundShipmentId }
        }
        if let apiStatus = status.apiStatus {
            items = items.filter { $0.status.rawValue == apiStatus }
        }
        return items
    }
}
