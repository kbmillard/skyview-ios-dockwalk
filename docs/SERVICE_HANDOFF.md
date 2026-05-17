# DockWalk iOS — service handoff

**Last updated:** 2026-05-17 (iOS Phase 1C — batch sync replay + putaway task list)

**Canonical backend:** [ARCHITECT_RECAP.md](https://github.com/kbmillard/skyview-dockwalk/blob/main/docs/architecture/ARCHITECT_RECAP.md)  
**API contract:** [api-foundation.md](https://github.com/kbmillard/skyview-dockwalk/blob/main/docs/contracts/api-foundation.md)  
**Sync contract:** [sync-contract.md](https://github.com/kbmillard/skyview-dockwalk/blob/main/docs/contracts/sync-contract.md)  
**Umbrella:** [DOCKWALK.md](https://github.com/kbmillard/SkyView/blob/main/docs/products/DOCKWALK.md)

---

## API base URLs

| Target | URL |
|--------|-----|
| **Railway production (iOS QA default)** | **https://dockwalk-api-production.up.railway.app** |
| Local (Simulator) | `http://localhost:8790` |

**More → API connection** — presets, Save & Test, **Reset to Railway QA** / **Reset to local API**.

New installs default to **Railway** (saved settings are never overwritten automatically).

---

## Supabase split (do not conflate)

| Project | Ref | Use on iOS |
|---------|-----|------------|
| Service (API) | `egasxwpnutwrqivwmufm` | **Never** — no service-role key on device |
| iOS client | `jllqgothyavoqvhugrvf` | App Connect / client SDK only (if used later) |

**Receiving writes:** Railway API only (`POST /api/inbound/receiving-events` or batch `POST /api/sync/events`). iOS does **not** insert receiving rows into Supabase directly.

---

## iOS-only status

| Area | Status |
|------|--------|
| **Receive workflow** | Appointments → shipments → lines → **Receive 1** |
| **Offline queue** | Receiving events persisted with payload + `idempotency_key` |
| **Batch replay** | `POST /api/sync/events` — `accepted` + `duplicate` clear queue items |
| **Per-event replay** | Fallback when `FeatureFlags.syncBatchReplayEnabled` is false |
| **Auto-replay** | **More → Sync** (default OFF) |
| **Manual replay** | **More → Debug → Replay receiving events** |
| **Putaway tasks** | **More → Putaway tasks** — `GET /api/tasks?task_type=putaway` (read-only) |
| **Audit trail** | **More → Activity → Audit events** |
| **Scanner / AI / payments / auth** | **OFF** |
| **TestFlight** | **Build 0.1.0 (1) uploaded** 2026-05-17 — processing in App Store Connect |

---

## Phase 1C delivery (2026-05-17)

**Backend (sibling `skyview-dockwalk`)**

- `POST /api/sync/events` — batch receiving replay (idempotent)
- `GET /api/tasks?task_type=putaway` — dev seed returns **2** tasks on Railway

**iOS flows**

1. Queued receiving events replay via **batch sync** (default path)
2. **More → Putaway tasks** — SKU, qty, from/to location, status filter
3. Sync status in **More → Sync** and **Today** reflects queue + replay messages

**Key files**

- `Networking/SyncBatchModels.swift`, `WarehouseTaskModels.swift`
- `Persistence/SyncBatchReplayEngine.swift`, `ReceivingEventReplayCoordinator.swift`
- `Tasks/PutawayTasksViewModel.swift`, `Tasks/TasksHomeView.swift`

**Validation**

```bash
cd apps/ios/dockwalk
xcodebuild -project DockWalk.xcodeproj -scheme DockWalk -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' test CODE_SIGNING_ALLOWED=NO
```

---

## Phase 1B (prior)

Inbound lines UI, device receiving POST, offline queue, Railway QA defaults, audit list.

---

## Suggested next iOS PR

| Priority | Work |
|----------|------|
| P1 | Putaway task detail + complete (when API adds writes) |
| P2 | Live scanner (replace manual Receive 1) |
| P3 | Auth / mobile session when service defines it |

---

## Cursor

Backend: **ARCHITECT_RECAP** + **api-foundation** + **sync-contract**. iOS: **this file**.
