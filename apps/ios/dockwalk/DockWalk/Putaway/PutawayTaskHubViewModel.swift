import Foundation
import Observation

/// Hub-level orchestration: which steps are saved, can the worker complete?
@Observable
final class PutawayTaskHubViewModel {
    let taskId: String
    private let sessionStore: PutawaySessionStore

    init(taskId: String, sessionStore: PutawaySessionStore = .shared) {
        self.taskId = taskId
        self.sessionStore = sessionStore
    }

    var savedDrafts: [PutawayConfirmDraft] {
        sessionStore.savedDrafts(for: taskId)
    }

    func saved(_ step: PutawayConfirmStep) -> PutawayConfirmDraft? {
        sessionStore.savedStep(for: taskId, step: step)
    }

    /// Minimum: to-location verified + quantity confirmed.
    func canComplete(for task: PutawayTaskItem) -> Bool {
        let toOK: Bool = {
            guard let draft = saved(.toLocation) else { return false }
            let expected = task.toLocationCode
            if expected.isEmpty { return !draft.scannedValue.isEmpty }
            return draft.scannedValue
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .compare(expected, options: .caseInsensitive) == .orderedSame
        }()
        let qtyOK = (saved(.quantity)?.confirmedQty ?? 0) > 0
        return toOK && qtyOK
    }

    func confirmedQuantity(for task: PutawayTaskItem) -> Double {
        saved(.quantity)?.confirmedQty ?? task.quantity
    }

    func clearSession() {
        sessionStore.clearTask(taskId)
    }

    func removeStep(_ step: PutawayConfirmStep) {
        guard let draft = saved(step) else { return }
        sessionStore.removeDraft(id: draft.id, taskId: taskId)
    }
}
