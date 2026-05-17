# DockWalk iOS — service handoff

**Last updated:** 2026-05-17 (iOS agent — runtime auto-replay toggle)

**Canonical backend:** [ARCHITECT_RECAP.md](https://github.com/kbmillard/skyview-dockwalk/blob/main/docs/architecture/ARCHITECT_RECAP.md)  
**API contract:** [api-foundation.md](https://github.com/kbmillard/skyview-dockwalk/blob/main/docs/contracts/api-foundation.md)  
**Umbrella:** [DOCKWALK.md](https://github.com/kbmillard/SkyView/blob/main/docs/products/DOCKWALK.md)

---

## API base URLs

| Target | URL |
|--------|-----|
| Local (Simulator) | `http://localhost:8790` |
| **Railway production** | `https://dockwalk-api-production.up.railway.app` |

**More → API connection** — presets + Save & Test.

---

## iOS-only status

| Area | Status |
|------|--------|
| **Receive workflow** | Appointments, shipments, lines, manual receive POST |
| **Offline queue** | Receiving events + original `idempotency_key` |
| **Manual replay** | **More → Debug → Replay receiving events** |
| **Auto-replay receiving** | **More → Sync → Auto-replay receiving events** toggle (UserDefaults, **default OFF**, **no rebuild**) |
| **Scanner / AI / payments / auth / direct Supabase** | **OFF** |

---

## Latest delivery (runtime auto-replay toggle)

**What changed**

- **`SyncPreferencesStore`** — `receivingEventAutoReplayEnabled` in UserDefaults (`DockWalk.receivingEventAutoReplayEnabled`), default **false**
- **More → Sync** — Toggle **Auto-replay receiving events** with helper footer; shows queued receiving count, last auto-replay time/summary, replaying state
- **`FeatureFlags`** — `receivingEventAutoReplayAvailable` (product gate); runtime toggle controls behavior (no `FeatureFlags.swift` edit for QA)
- **Turn ON** with queued items: one safe replay if health OK + throttle allows; otherwise hint text for next health/foreground/Receive refresh
- **Turn OFF** — stops auto attempts; queue unchanged
- **Manual Debug replay** — unchanged; does not require toggle ON

**Files (main)**

- `Persistence/SyncPreferencesStore.swift`
- `Persistence/ReceivingEventReplayCoordinator.swift`
- `Core/FeatureFlags.swift`
- `Settings/SettingsView.swift`
- `App/DockWalkApp.swift`
- `DockWalkTests/DockWalkFoundationTests.swift`

**Still off:** scanner, Gemini, payments, auth, direct Supabase.

**Validation (2026-05-17)**

```bash
cd apps/ios/dockwalk
xcodebuild -project DockWalk.xcodeproj -scheme DockWalk -destination 'generic/platform=iOS' build CODE_SIGNING_ALLOWED=NO
# BUILD SUCCEEDED

xcodebuild -project DockWalk.xcodeproj -scheme DockWalk -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' test CODE_SIGNING_ALLOWED=NO
# TEST SUCCEEDED — 24 tests
```

**Limitations**

- Only **receiving events** auto-replay; `inbound.start` / `exception` never auto-replay.
- 30s throttle between auto attempts (`ReceivingEventReplayCoordinator.autoReplayMinimumInterval`).
- Toggle requires **offline sync** product gate (`FeatureFlags.offlineSyncEnabled`).

---

## Prior delivery (8c443cb)

Auto-replay engine (receiving-only, idempotency-safe, duplicate = success, in-flight + throttle). Triggers: foreground, health OK, Receive load. Was compile-time flag only.

## Prior delivery (313b861)

Inbound lines, manual receive POST, Railway preset, offline queue.

---

## Suggested next iOS PR

| Priority | Work |
|----------|------|
| P1 | Auth / mobile session when service defines it |
| P2 | Live scanner; audit list read |

---

## Cursor

Backend: **ARCHITECT_RECAP**. iOS: **this file**.
