import Foundation
import Observation

@Observable
final class ReceivingEventReplayCoordinator {
    static let shared = ReceivingEventReplayCoordinator()

    /// Minimum seconds between automatic replay attempts (avoids tight loops).
    static let autoReplayMinimumInterval: TimeInterval = 30

    private(set) var isReplaying = false
    private(set) var lastAutoReplayAt: Date?
    private(set) var lastAutoReplaySummary: String?

    private var lastAttemptAt: Date?

    private init() {}

    @discardableResult
    func attemptAutoReplayIfNeeded(
        environment: AppEnvironment,
        syncStore: OfflineSyncStore,
        trigger: String
    ) async -> ReceivingEventReplayOutcome? {
        guard FeatureFlags.autoReplayReceivingEventsEnabled else { return nil }
        guard FeatureFlags.offlineSyncEnabled else { return nil }
        guard syncStore.pendingReceivingEventCount > 0 else { return nil }
        guard !isReplaying else { return nil }

        if let lastAttemptAt,
           Date().timeIntervalSince(lastAttemptAt) < Self.autoReplayMinimumInterval {
            return nil
        }

        let client = environment.makeAPIClient()
        guard await client.healthCheck() else { return nil }

        return await replayReceivingEvents(
            environment: environment,
            syncStore: syncStore,
            label: "Auto (\(trigger))"
        )
    }

    @discardableResult
    func replayReceivingEvents(
        environment: AppEnvironment,
        syncStore: OfflineSyncStore,
        label: String
    ) async -> ReceivingEventReplayOutcome {
        guard !isReplaying else {
            return ReceivingEventReplayOutcome(succeeded: 0, failed: 0, removedActionIDs: [])
        }

        isReplaying = true
        lastAttemptAt = Date()
        defer { isReplaying = false }

        syncStore.markSyncing()
        let client = environment.makeAPIClient()

        let outcome = await ReceivingEventReplayEngine.replay(actions: syncStore.queuedActions) { payload in
            try await client.post(.receivingEvents, body: payload)
        }

        syncStore.removeQueuedActions(withIDs: Set(outcome.removedActionIDs))

        let message: String
        if outcome.succeeded == 0 && outcome.failed == 0 {
            message = "\(label): no receiving events in queue."
        } else {
            message = "\(label): \(outcome.succeeded) sent, \(outcome.failed) still pending."
        }

        syncStore.recordReplayMessage(message)
        if label.hasPrefix("Auto") {
            lastAutoReplayAt = Date()
            lastAutoReplaySummary = message
        }

        return outcome
    }
}
