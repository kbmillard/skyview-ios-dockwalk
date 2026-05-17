import Foundation
import Observation

enum PutawayActionBannerTone {
    case neutral, success, warning, danger

    var statusChipTone: StatusChip.Tone {
        switch self {
        case .neutral: return .neutral
        case .success: return .success
        case .warning: return .warning
        case .danger: return .danger
        }
    }
}

@Observable
final class PutawayTaskDetailViewModel {
    private(set) var task: PutawayTaskItem?
    private(set) var loadPhase: LoadPhase = .idle
    private(set) var dataMode: String?
    private(set) var isSubmittingAction = false
    private(set) var actionBannerMessage: String?
    private(set) var actionBannerTone: PutawayActionBannerTone = .neutral

    var onTaskUpdated: (() -> Void)?

    private let taskId: String
    private let environment: AppEnvironment
    private var pendingAction: PendingAction?

    private struct PendingAction {
        let kind: PutawayTaskActionKind
        let idempotencyKey: String
    }

    init(taskId: String, initialTask: PutawayTaskItem? = nil, environment: AppEnvironment = .shared) {
        self.taskId = taskId
        self.task = initialTask
        self.environment = environment
        if initialTask != nil {
            loadPhase = .loaded
        }
    }

    var availableActions: [PutawayTaskActionKind] {
        guard let task else { return [] }
        return PutawayTaskActionAvailability.availableActions(for: task.status)
    }

    func load() async {
        if task == nil {
            loadPhase = .loading
        }

        let apiClient = environment.makeAPIClient()

        do {
            let response = try await apiClient.fetchTask(id: taskId, orgId: environment.orgId)
            dataMode = response.mode
            task = WarehouseTaskAPIMapping.mapTask(response.item)
            loadPhase = .loaded
        } catch {
            if task == nil {
                loadPhase = .error(message: userFacingError(error))
            }
        }
    }

    func performAction(_ kind: PutawayTaskActionKind, blockReason: String? = nil) async {
        guard !isSubmittingAction else { return }

        let idempotencyKey = idempotencyKey(for: kind)
        isSubmittingAction = true
        actionBannerMessage = nil
        defer { isSubmittingAction = false }

        let apiClient = environment.makeAPIClient()
        let orgId = environment.orgId
        let deviceId = ReceivingEventBuilder.deviceId

        do {
            let response: WarehouseTaskWriteResponse
            switch kind {
            case .assign:
                response = try await apiClient.assignTask(
                    taskId: taskId,
                    body: TaskAssignRequest(
                        orgId: orgId,
                        assignedTo: WarehouseTaskActionIdempotency.operatorId,
                        idempotencyKey: idempotencyKey,
                        deviceId: deviceId,
                        notes: nil
                    )
                )
            case .start:
                response = try await apiClient.startTask(
                    taskId: taskId,
                    body: TaskStartRequest(
                        orgId: orgId,
                        idempotencyKey: idempotencyKey,
                        deviceId: deviceId,
                        notes: nil
                    )
                )
            case .block:
                let reason = (blockReason ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                guard !reason.isEmpty else {
                    actionBannerMessage = "Enter a block reason."
                    actionBannerTone = .warning
                    return
                }
                response = try await apiClient.blockTask(
                    taskId: taskId,
                    body: TaskBlockRequest(
                        orgId: orgId,
                        reasonCode: "other",
                        reason: reason,
                        idempotencyKey: idempotencyKey,
                        deviceId: deviceId,
                        notes: nil
                    )
                )
            case .complete:
                response = try await apiClient.completeTask(
                    taskId: taskId,
                    body: TaskCompleteRequest(
                        orgId: orgId,
                        idempotencyKey: idempotencyKey,
                        deviceId: deviceId,
                        performedBy: WarehouseTaskActionIdempotency.operatorId,
                        quantityCompleted: task?.quantity,
                        notes: nil
                    )
                )
            }

            pendingAction = nil
            dataMode = response.mode
            task = WarehouseTaskAPIMapping.mapTask(response.item)
            loadPhase = .loaded

            if response.isIdempotentReplay {
                actionBannerMessage = "\(kind.title) already recorded on the server."
                actionBannerTone = .success
            } else {
                actionBannerMessage = "\(kind.title) submitted."
                actionBannerTone = .success
            }

            onTaskUpdated?()
        } catch {
            let mapped = WarehouseTaskActionErrorMapping.map(error)
            actionBannerMessage = mapped.message
            actionBannerTone = mapped.isConflict ? .warning : .danger

            if mapped.preserveIdempotencyKey {
                pendingAction = PendingAction(kind: kind, idempotencyKey: idempotencyKey)
            } else {
                pendingAction = nil
            }

            if mapped.isConflict {
                await load()
                onTaskUpdated?()
            }
        }
    }

    func clearActionBanner() {
        actionBannerMessage = nil
    }

    private func idempotencyKey(for kind: PutawayTaskActionKind) -> String {
        if let pending = pendingAction, pending.kind == kind {
            return pending.idempotencyKey
        }
        return WarehouseTaskActionIdempotency.makeKey()
    }

    private func userFacingError(_ error: Error) -> String {
        if let apiError = error as? APIClientError {
            return apiError.errorDescription ?? "Request failed."
        }
        return error.localizedDescription
    }
}
