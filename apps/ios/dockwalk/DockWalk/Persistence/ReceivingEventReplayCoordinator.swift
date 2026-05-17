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
    private(set) var pendingAutoReplayHint: String?

    private var lastAttemptAt: Date?
    private let preferences: SyncPreferencesStore

    init(preferences: SyncPreferencesStore = .shared) {
        self.preferences = preferences
    }

    var isAutoReplayEnabled: Bool {
        FeatureFlags.isReceivingEventAutoReplayPermitted && preferences.receivingEventAutoReplayEnabled
    }

    @discardableResult
    func attemptAutoReplayIfNeeded(
        environment: AppEnvironment,
        syncStore: OfflineSyncStore,
        trigger: String
    ) async -> ReceivingEventReplayOutcome? {
        guard isAutoReplayEnabled else { return nil }
        guard syncStore.pendingReceivingEventCount > 0 else { return nil }
        guard !isReplaying else { return nil }

        if let lastAttemptAt,
           Date().timeIntervalSince(lastAttemptAt) < Self.autoReplayMinimumInterval {
            return nil
        }

        let client = environment.makeAPIClient()
        guard await client.healthCheck() else { return nil }

        pendingAutoReplayHint = nil
        return await replayReceivingEvents(
            environment: environment,
            syncStore: syncStore,
            label: "Auto (\(trigger))"
        )
    }

    func handleAutoReplayEnabledByUser(
        environment: AppEnvironment,
        syncStore: OfflineSyncStore
    ) async {
        guard isAutoReplayEnabled else { return }
        guard syncStore.pendingReceivingEventCount > 0 else {
            pendingAutoReplayHint = nil
            return
        }

        let client = environment.makeAPIClient()
        if await client.healthCheck() {
            if let outcome = await attemptAutoReplayIfNeeded(
                environment: environment,
                syncStore: syncStore,
                trigger: "toggle_on"
            ), outcome.succeeded > 0 || outcome.failed > 0 {
                return
            }
        }

        pendingAutoReplayHint =
            "Auto-replay enabled. Will run after the next successful health check, app foreground, or Receive refresh."
    }

    func handleAutoReplayDisabledByUser() {
        pendingAutoReplayHint = nil
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

        let outcome: ReceivingEventReplayOutcome
        if FeatureFlags.syncBatchReplayEnabled {
            outcome = await SyncBatchReplayEngine.replay(actions: syncStore.queuedActions) { envelope in
                try await client.postSyncEvents(envelope)
            }
        } else {
            outcome = await ReceivingEventReplayEngine.replay(actions: syncStore.queuedActions) { payload in
                try await client.post(.receivingEvents, body: payload)
            }
        }

        syncStore.removeQueuedActions(withIDs: Set(outcome.removedActionIDs))

        let message: String
        if outcome.succeeded == 0 && outcome.failed == 0 {
            message = "\(label): no receiving events in queue."
        } else {
            let via = FeatureFlags.syncBatchReplayEnabled ? "batch sync" : "per-event"
            message = "\(label) (\(via)): \(outcome.succeeded) sent, \(outcome.failed) still pending."
        }

        syncStore.recordReplayMessage(message)
        syncStore.markOnline()
        if label.hasPrefix("Auto") {
            lastAutoReplayAt = Date()
            lastAutoReplaySummary = message
        }

        return outcome
    }
}
