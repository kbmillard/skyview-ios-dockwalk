import Foundation

/// Dev-seed-aligned preview data when the DockWalk API host is unreachable.
/// 30 scheduled loads for testing the full inbound workflow from the beginning.
enum FoundationOperationalData {
    /// Rebuilt on each access — all 30 scheduled on demo queue Friday (+1 week).
    static var receivingAppointments: [ReceivingAppointment] {
        demoReceivingAppointments()
    }

    static var demoQueueScheduleDay: Date {
        InboundWeekSchedule.demoInboundQueueDay()
    }

    private struct DemoLoadSeed {
        let id: String
        let carrier: String
        let poNumber: String
        let palletCount: Int
        let vendor: String?
    }

    private static let demoLoadSeeds: [DemoLoadSeed] = [
        DemoLoadSeed(id: "T-4401", carrier: "Old Dominion", poNumber: "T-4401", palletCount: 24, vendor: "Midwest Parts"),
        DemoLoadSeed(id: "T-4402", carrier: "XPO Logistics", poNumber: "T-4402", palletCount: 18, vendor: "Apex Supply"),
        DemoLoadSeed(id: "T-4403", carrier: "JB Hunt", poNumber: "T-4403", palletCount: 32, vendor: nil),
        DemoLoadSeed(id: "T-4404", carrier: "FedEx Freight", poNumber: "T-4404", palletCount: 12, vendor: "Central Wholesale"),
        DemoLoadSeed(id: "T-4405", carrier: "Estes Express", poNumber: "T-4405", palletCount: 16, vendor: nil),
        DemoLoadSeed(id: "T-4406", carrier: "ABF Freight", poNumber: "T-4406", palletCount: 28, vendor: "Summit Distribution"),
        DemoLoadSeed(id: "T-4407", carrier: "Saia LTL", poNumber: "T-4407", palletCount: 20, vendor: nil),
        DemoLoadSeed(id: "T-4408", carrier: "R+L Carriers", poNumber: "T-4408", palletCount: 14, vendor: "Pacific Components"),
        DemoLoadSeed(id: "T-4409", carrier: "Dayton Freight", poNumber: "T-4409", palletCount: 22, vendor: nil),
        DemoLoadSeed(id: "T-4410", carrier: "Old Dominion", poNumber: "T-4410", palletCount: 30, vendor: "Eastern Industrial"),
        DemoLoadSeed(id: "T-4411", carrier: "XPO Logistics", poNumber: "T-4411", palletCount: 26, vendor: nil),
        DemoLoadSeed(id: "T-4412", carrier: "FedEx Freight", poNumber: "T-4412", palletCount: 18, vendor: "Midwest Parts"),
        DemoLoadSeed(id: "T-4413", carrier: "JB Hunt", poNumber: "T-4413", palletCount: 34, vendor: "Apex Supply"),
        DemoLoadSeed(id: "T-4414", carrier: "Estes Express", poNumber: "T-4414", palletCount: 16, vendor: nil),
        DemoLoadSeed(id: "T-4415", carrier: "ABF Freight", poNumber: "T-4415", palletCount: 20, vendor: "Central Wholesale"),
        DemoLoadSeed(id: "T-4416", carrier: "Saia LTL", poNumber: "T-4416", palletCount: 24, vendor: nil),
        DemoLoadSeed(id: "T-4417", carrier: "R+L Carriers", poNumber: "T-4417", palletCount: 12, vendor: "Summit Distribution"),
        DemoLoadSeed(id: "T-4418", carrier: "Dayton Freight", poNumber: "T-4418", palletCount: 28, vendor: nil),
        DemoLoadSeed(id: "T-4419", carrier: "Old Dominion", poNumber: "T-4419", palletCount: 22, vendor: "Pacific Components"),
        DemoLoadSeed(id: "T-4420", carrier: "XPO Logistics", poNumber: "T-4420", palletCount: 30, vendor: nil),
        DemoLoadSeed(id: "T-4421", carrier: "FedEx Freight", poNumber: "T-4421", palletCount: 20, vendor: "Eastern Industrial"),
        DemoLoadSeed(id: "T-4422", carrier: "JB Hunt", poNumber: "T-4422", palletCount: 36, vendor: nil),
        DemoLoadSeed(id: "T-4423", carrier: "Estes Express", poNumber: "T-4423", palletCount: 18, vendor: "Midwest Parts"),
        DemoLoadSeed(id: "T-4424", carrier: "ABF Freight", poNumber: "T-4424", palletCount: 26, vendor: "Apex Supply"),
        DemoLoadSeed(id: "T-4425", carrier: "Saia LTL", poNumber: "T-4425", palletCount: 14, vendor: nil),
        DemoLoadSeed(id: "T-4426", carrier: "R+L Carriers", poNumber: "T-4426", palletCount: 22, vendor: "Central Wholesale"),
        DemoLoadSeed(id: "T-4427", carrier: "Dayton Freight", poNumber: "T-4427", palletCount: 28, vendor: nil),
        DemoLoadSeed(id: "T-4428", carrier: "Old Dominion", poNumber: "T-4428", palletCount: 32, vendor: "Summit Distribution"),
        DemoLoadSeed(id: "T-4429", carrier: "XPO Logistics", poNumber: "T-4429", palletCount: 16, vendor: nil),
        DemoLoadSeed(id: "T-4430", carrier: "FedEx Freight", poNumber: "T-4430", palletCount: 24, vendor: "Pacific Components"),
    ]

    private static func demoReceivingAppointments() -> [ReceivingAppointment] {
        let calendar = Calendar.current
        let queueDay = InboundWeekSchedule.demoInboundQueueDay(calendar: calendar)

        return demoLoadSeeds.enumerated().map { index, seed in
            // All 30 on demo queue Friday, staggered 6:00 AM – ~8:00 PM.
            let hour = 6 + (index * 14 / max(demoLoadSeeds.count - 1, 1))
            let minute = (index * 13) % 60
            let scheduledAt = calendar.date(
                bySettingHour: hour,
                minute: minute,
                second: 0,
                of: queueDay
            ) ?? queueDay.addingTimeInterval(TimeInterval(index + 1) * 3600)

            return ReceivingAppointment(
                id: seed.id,
                carrier: seed.carrier,
                dock: "",
                scheduledAt: scheduledAt,
                status: .scheduled,
                poNumber: seed.poNumber,
                palletCount: seed.palletCount,
                vendor: seed.vendor,
                expectedLineCount: 0,
                receivedLineCount: 0,
                doorNumber: nil
            )
        }
    }

    // Empty - all putaway data will be created through user actions
    static let putawayTasks: [PutawayTaskItem] = []

    static func putawayTasks(
        filteredBy inboundShipmentId: String?,
        status: PutawayTaskStatusFilter
    ) -> [PutawayTaskItem] {
        []
    }
    
    // 30 dock doors for assignment
    static let dockDoors: [DockDoorStatus] = [
        DockDoorStatus(id: "D-01", doorNumber: "D-01", status: .open, assignedLoad: nil),
        DockDoorStatus(id: "D-02", doorNumber: "D-02", status: .open, assignedLoad: nil),
        DockDoorStatus(id: "D-03", doorNumber: "D-03", status: .open, assignedLoad: nil),
        DockDoorStatus(id: "D-04", doorNumber: "D-04", status: .open, assignedLoad: nil),
        DockDoorStatus(id: "D-05", doorNumber: "D-05", status: .open, assignedLoad: nil),
        DockDoorStatus(id: "D-06", doorNumber: "D-06", status: .open, assignedLoad: nil),
        DockDoorStatus(id: "D-07", doorNumber: "D-07", status: .open, assignedLoad: nil),
        DockDoorStatus(id: "D-08", doorNumber: "D-08", status: .open, assignedLoad: nil),
        DockDoorStatus(id: "D-09", doorNumber: "D-09", status: .open, assignedLoad: nil),
        DockDoorStatus(id: "D-10", doorNumber: "D-10", status: .open, assignedLoad: nil),
        DockDoorStatus(id: "D-11", doorNumber: "D-11", status: .open, assignedLoad: nil),
        DockDoorStatus(id: "D-12", doorNumber: "D-12", status: .open, assignedLoad: nil),
        DockDoorStatus(id: "D-13", doorNumber: "D-13", status: .open, assignedLoad: nil),
        DockDoorStatus(id: "D-14", doorNumber: "D-14", status: .open, assignedLoad: nil),
        DockDoorStatus(id: "D-15", doorNumber: "D-15", status: .open, assignedLoad: nil),
        DockDoorStatus(id: "D-16", doorNumber: "D-16", status: .open, assignedLoad: nil),
        DockDoorStatus(id: "D-17", doorNumber: "D-17", status: .open, assignedLoad: nil),
        DockDoorStatus(id: "D-18", doorNumber: "D-18", status: .open, assignedLoad: nil),
        DockDoorStatus(id: "D-19", doorNumber: "D-19", status: .open, assignedLoad: nil),
        DockDoorStatus(id: "D-20", doorNumber: "D-20", status: .open, assignedLoad: nil),
        DockDoorStatus(id: "D-21", doorNumber: "D-21", status: .open, assignedLoad: nil),
        DockDoorStatus(id: "D-22", doorNumber: "D-22", status: .open, assignedLoad: nil),
        DockDoorStatus(id: "D-23", doorNumber: "D-23", status: .open, assignedLoad: nil),
        DockDoorStatus(id: "D-24", doorNumber: "D-24", status: .open, assignedLoad: nil),
        DockDoorStatus(id: "D-25", doorNumber: "D-25", status: .open, assignedLoad: nil),
        DockDoorStatus(id: "D-26", doorNumber: "D-26", status: .open, assignedLoad: nil),
        DockDoorStatus(id: "D-27", doorNumber: "D-27", status: .open, assignedLoad: nil),
        DockDoorStatus(id: "D-28", doorNumber: "D-28", status: .open, assignedLoad: nil),
        DockDoorStatus(id: "D-29", doorNumber: "D-29", status: .open, assignedLoad: nil),
        DockDoorStatus(id: "D-30", doorNumber: "D-30", status: .open, assignedLoad: nil),
    ]
}
