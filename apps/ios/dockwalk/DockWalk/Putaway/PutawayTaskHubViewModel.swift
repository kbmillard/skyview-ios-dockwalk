import Foundation
import Observation

/// Hub-level orchestration: which steps are saved, can the worker complete?
@Observable
final class PutawayTaskHubViewModel {
    let cardId: String
    private let sessionStore: PutawaySessionStore

    init(cardId: String, sessionStore: PutawaySessionStore = .shared) {
        self.cardId = cardId
        self.sessionStore = sessionStore
    }

    var savedDrafts: [PutawayConfirmDraft] {
        sessionStore.savedDrafts(for: cardId)
    }

    func saved(_ step: PutawayConfirmStep) -> PutawayConfirmDraft? {
        sessionStore.savedStep(for: cardId, step: step)
    }

    /// Minimum: UPC verified + to bin scanned + quantity confirmed.
    func canComplete(for card: PutawayUPCCard) -> Bool {
        let upcOK: Bool = {
            guard let draft = saved(.upc) else { return false }
            return draft.scannedValue
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .compare(card.upc, options: .caseInsensitive) == .orderedSame
        }()
        let toOK = !(saved(.toLocation)?.scannedValue
            .trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
        let qtyOK = (saved(.quantity)?.confirmedQty ?? 0) > 0
        return upcOK && toOK && qtyOK
    }

    func confirmedQuantity(for card: PutawayUPCCard) -> Double {
        saved(.quantity)?.confirmedQty ?? card.quantity
    }

    func clearSession() {
        sessionStore.clearTask(cardId)
    }

    func removeStep(_ step: PutawayConfirmStep) {
        guard let draft = saved(step) else { return }
        sessionStore.removeDraft(id: draft.id, taskId: cardId)
    }
}
