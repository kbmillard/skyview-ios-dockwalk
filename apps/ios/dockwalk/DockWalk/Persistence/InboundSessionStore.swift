import Foundation
import Observation

/// In-memory inbound session for demo mode: load mutations and received inventory survive tab switches.
@Observable
final class InboundSessionStore {
    static let shared = InboundSessionStore()

    private static let stageKey = "SkyView.inboundSelectedStage"
    private static let scheduleDayKey = "SkyView.inboundSelectedScheduleDay"

    private(set) var revision = 0
    private var demoLoads: [ReceivingAppointment]?
    private var receivedByLoadId: [String: [ReceiveInventoryDraft]] = [:]

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    // MARK: - Demo loads

    func seedDemoLoadsIfNeeded() -> [ReceivingAppointment] {
        if let demoLoads { return demoLoads }
        let seeded = FoundationOperationalData.receivingAppointments
        demoLoads = seeded
        bumpRevision()
        return seeded
    }

    func resetDemoLoads() {
        demoLoads = nil
        receivedByLoadId = [:]
        bumpRevision()
    }

    func updateLoad(_ load: ReceivingAppointment) {
        guard var loads = demoLoads,
              let index = loads.firstIndex(where: { $0.id == load.id })
        else { return }
        loads[index] = load
        demoLoads = loads
        bumpRevision()
    }

    func insertLoad(_ load: ReceivingAppointment) {
        var loads = demoLoads ?? seedDemoLoadsIfNeeded()
        loads.insert(load, at: 0)
        demoLoads = loads
        bumpRevision()
    }

    // MARK: - Received inventory

    func receivedItems(for loadId: String) -> [ReceiveInventoryDraft] {
        receivedByLoadId[loadId] ?? []
    }

    func saveReceivedItems(loadId: String, items: [ReceiveInventoryDraft]) {
        receivedByLoadId[loadId] = items
        bumpRevision()
    }

    // MARK: - Inbound list UI prefs

    var selectedStageRaw: String {
        get { defaults.string(forKey: Self.stageKey) ?? InboundStageFilter.scheduled.rawValue }
        set {
            defaults.set(newValue, forKey: Self.stageKey)
            bumpRevision()
        }
    }

    var selectedScheduleDay: Date {
        get {
            let interval = defaults.double(forKey: Self.scheduleDayKey)
            if interval > 0 {
                return Date(timeIntervalSince1970: interval)
            }
            return InboundWeekSchedule.demoInboundQueueDay()
        }
        set {
            defaults.set(newValue.timeIntervalSince1970, forKey: Self.scheduleDayKey)
            bumpRevision()
        }
    }

    private func bumpRevision() {
        revision += 1
    }
}
