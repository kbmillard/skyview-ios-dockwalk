import Foundation
import Observation

/// In-memory inbound session for demo mode: load mutations and received inventory survive tab switches.
@Observable
final class InboundSessionStore {
    static let shared = InboundSessionStore()

    private static let stageKey = "SkyView.inboundSelectedStage"
    private static let scheduleDayKey = "SkyView.inboundSelectedScheduleDay"

    private(set) var revision = 0
    /// Bumped when received inventory is saved or cleared; used by Load Detail without resetting navigation.
    private(set) var receivedInventoryRevision = 0
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

    func resetDemoLoads(clearReceivedInventory: Bool = true) {
        demoLoads = nil
        if clearReceivedInventory {
            receivedByLoadId = [:]
            bumpReceivedInventoryRevision()
        }
        bumpRevision()
    }

    /// Resets cached demo loads only (keeps receive drafts on pull-to-refresh).
    func resetDemoLoadsCache() {
        resetDemoLoads(clearReceivedInventory: false)
    }

    func updateLoad(_ load: ReceivingAppointment) {
        guard var loads = demoLoads,
              let index = loads.firstIndex(where: { $0.id == load.id })
        else { return }
        loads[index] = load
        demoLoads = loads
    }

    func insertLoad(_ load: ReceivingAppointment) {
        var loads = demoLoads ?? seedDemoLoadsIfNeeded()
        loads.insert(load, at: 0)
        demoLoads = loads
    }

    // MARK: - Received inventory

    func receivedItems(for loadId: String) -> [ReceiveInventoryDraft] {
        receivedByLoadId[loadId] ?? []
    }

    func saveReceivedItems(loadId: String, items: [ReceiveInventoryDraft]) {
        receivedByLoadId[loadId] = items
        bumpReceivedInventoryRevision()
    }

    /// Promotes saved receive drafts to the global inventory catalog when a load is finalized.
    @discardableResult
    func commitReceivedInventoryToCatalog(
        loadId: String,
        catalog: InventoryCatalogStore = .shared
    ) -> Int {
        let items = receivedItems(for: loadId)
        var committed = 0
        var updated = items
        for index in updated.indices {
            guard updated[index].isSaved, !updated[index].isCommittedToCatalog else { continue }
            guard let inventoryItem = updated[index].makeInventoryItem() else { continue }
            catalog.add(inventoryItem)
            updated[index].isCommittedToCatalog = true
            committed += 1
        }
        if committed > 0 {
            receivedByLoadId[loadId] = updated
            bumpReceivedInventoryRevision()
        }
        return committed
    }

    // MARK: - Inbound list UI prefs

    var selectedStageRaw: String {
        get { defaults.string(forKey: Self.stageKey) ?? InboundStageFilter.scheduled.rawValue }
        set { defaults.set(newValue, forKey: Self.stageKey) }
    }

    var selectedScheduleDay: Date {
        get {
            let interval = defaults.double(forKey: Self.scheduleDayKey)
            if interval > 0 {
                return Date(timeIntervalSince1970: interval)
            }
            return InboundWeekSchedule.demoInboundQueueDay()
        }
        set { defaults.set(newValue.timeIntervalSince1970, forKey: Self.scheduleDayKey) }
    }

    private func bumpRevision() {
        revision += 1
    }

    private func bumpReceivedInventoryRevision() {
        receivedInventoryRevision += 1
    }
}
