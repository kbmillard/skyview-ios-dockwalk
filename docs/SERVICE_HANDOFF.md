# DockWalk iOS — service handoff

**Last updated:** 2026-05-17 (iOS agent — receiving-event auto-replay)

**Canonical system state (API, Supabase service DB, workers, phases):**  
[ARCHITECT_RECAP.md](https://github.com/kbmillard/skyview-dockwalk/blob/main/docs/architecture/ARCHITECT_RECAP.md)

**API contract (paths, query params, stub vs live):**  
[api-foundation.md](https://github.com/kbmillard/skyview-dockwalk/blob/main/docs/contracts/api-foundation.md)

**Umbrella index:** [DOCKWALK.md](https://github.com/kbmillard/SkyView/blob/main/docs/products/DOCKWALK.md)

---

## Repo split

| | This repo | [skyview-dockwalk](https://github.com/kbmillard/skyview-dockwalk) |
|--|-----------|-------------------------------------------------------------------|
| **Owns** | SwiftUI, offline queue, device config | Express API, migrations, portal worker, Railway |
| **Supabase** | `jllqgothyavoqvhugrvf` (client) | `egasxwpnutwrqivwmufm` (server) |

---

## API base URLs

| Target | URL |
|--------|-----|
| Local (Simulator) | `http://localhost:8790` |
| Local (device) | `http://<Mac-LAN-IP>:8790` |
| **Railway production** | `https://dockwalk-api-production.up.railway.app` |

Set in app: **More → API connection** (presets for Railway / localhost).

---

## iOS-only status

| Area | Status |
|------|--------|
| **API connection** | Persisted URL/org/facility; Railway + localhost presets |
| **Receive workflow** | Appointments, shipments, lines, manual receive POST |
| **Offline queue** | Receiving events store full payload + original `idempotency_key` |
| **Manual replay** | **More → Debug → Replay receiving events** |
| **Auto-replay receiving** | **OFF by default** (`FeatureFlags.autoReplayReceivingEventsEnabled`) — see below |
| **Scanner / AI / payments / auth / direct Supabase** | **OFF** |

---

## Latest delivery (receiving-event auto-replay)

**What changed**

- **`autoReplayReceivingEventsEnabled`** — default **`false`** (conservative; enable in `FeatureFlags.swift` for QA)
- **`ReceivingEventReplayEngine`** — replays only `inbound.receiving_event` actions; preserves idempotency keys; duplicate API responses count as success; partial failure leaves failed items queued
- **`ReceivingEventReplayCoordinator`** — in-flight guard + 30s throttle between auto attempts
- **Auto triggers** (when flag ON + health OK + queue non-empty):
  - App foreground
  - Successful **Test API connection**
  - Receive tab load after successful appointments fetch
- **UI:** More → Sync shows queued receiving count, replaying state, last auto-replay summary; Receive banner shows queued count; API connection labels/monospace for long URL/UUIDs
- **Manual Debug replay** unchanged

**Files (main)**

- `Core/FeatureFlags.swift`
- `Persistence/ReceivingEventReplayEngine.swift`, `ReceivingEventReplayCoordinator.swift`
- `Persistence/OfflineSyncStore.swift`
- `App/DockWalkApp.swift`
- `Inbound/AppointmentsView.swift`, `Inbound/AppointmentsViewModel.swift`
- `Settings/APIConnectionSettingsView.swift`, `Settings/SettingsView.swift`
- `Debug/DebugPanelView.swift`
- `DockWalkTests/DockWalkFoundationTests.swift`

**Validation (2026-05-17)**

```bash
cd apps/ios/dockwalk
xcodebuild -project DockWalk.xcodeproj -scheme DockWalk \
  -destination 'generic/platform=iOS' build CODE_SIGNING_ALLOWED=NO
# BUILD SUCCEEDED

xcodebuild -project DockWalk.xcodeproj -scheme DockWalk \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' test CODE_SIGNING_ALLOWED=NO
# TEST SUCCEEDED — 19 tests
```

**Limitations**

- Auto-replay is **flag-off** until you flip `autoReplayReceivingEventsEnabled` to `true`.
- **`inbound.start`** and **`exception`** queue kinds are never auto-replayed.
- Throttle: at most one auto attempt per 30s (see `ReceivingEventReplayCoordinator.autoReplayMinimumInterval`).

---

## Prior delivery (313b861)

Inbound lines UI, manual receive POST, Railway preset, offline queue, Debug manual replay — 15 tests.

---

## Suggested next iOS PR

| Priority | Work |
|----------|------|
| P1 | UserDefaults toggle for auto-replay (no rebuild) |
| P2 | Auth / mobile session when service defines it |
| P3 | Live scanner; audit list read |

---

## Cursor

Backend truth: **ARCHITECT_RECAP**. iOS truth: **this file**.
