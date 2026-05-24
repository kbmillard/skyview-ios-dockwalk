import Foundation
import Observation

/// In-memory per-task draft store for putaway confirmation steps.
///
/// Mirrors `InboundSessionStore` — keys by taskId, exposes a revision bump for
/// passive UI refresh, and does not persist across app launches.
@Observable
final class PutawaySessionStore {
    static let shared = PutawaySessionStore()

    private(set) var revision: Int = 0
    private var draftsByTaskId: [String: [PutawayConfirmDraft]] = [:]

    // MARK: Read

    func drafts(for taskId: String) -> [PutawayConfirmDraft] {
        draftsByTaskId[taskId] ?? []
    }

    func savedDrafts(for taskId: String) -> [PutawayConfirmDraft] {
        drafts(for: taskId).filter(\.isSaved)
    }

    func savedStep(for taskId: String, step: PutawayConfirmStep) -> PutawayConfirmDraft? {
        savedDrafts(for: taskId).first { $0.step == step }
    }

    // MARK: Write

    func appendDraft(_ draft: PutawayConfirmDraft) {
        var list = drafts(for: draft.taskId)
        list.append(draft)
        draftsByTaskId[draft.taskId] = list
        bumpRevision()
    }

    func updateDraft(_ draft: PutawayConfirmDraft) {
        var list = drafts(for: draft.taskId)
        guard let idx = list.firstIndex(where: { $0.id == draft.id }) else { return }
        list[idx] = draft
        draftsByTaskId[draft.taskId] = list
        bumpRevision()
    }

    func removeDraft(id: String, taskId: String) {
        var list = drafts(for: taskId)
        list.removeAll { $0.id == id }
        draftsByTaskId[taskId] = list
        bumpRevision()
    }

    /// Save the latest unsaved draft for a step (replaces any prior saved row for the same step).
    func saveDraft(_ draft: PutawayConfirmDraft) -> Bool {
        var list = drafts(for: draft.taskId)
        list.removeAll { $0.isSaved && $0.step == draft.step && $0.id != draft.id }
        guard let idx = list.firstIndex(where: { $0.id == draft.id }) else { return false }
        var updated = draft
        updated.isSaved = true
        list[idx] = updated
        draftsByTaskId[draft.taskId] = list
        bumpRevision()
        return true
    }

    func clearTask(_ taskId: String) {
        draftsByTaskId[taskId] = nil
        bumpRevision()
    }

    private func bumpRevision() {
        revision &+= 1
    }
}
