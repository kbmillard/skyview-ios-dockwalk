# DockWalk iOS — service handoff

**Last updated:** 2026-05-17 (TestFlight internal live · Phase 1C + first ship)

**Canonical backend:** [ARCHITECT_RECAP.md](https://github.com/kbmillard/skyview-dockwalk/blob/main/docs/architecture/ARCHITECT_RECAP.md)  
**API contract:** [api-foundation.md](https://github.com/kbmillard/skyview-dockwalk/blob/main/docs/contracts/api-foundation.md)  
**Sync contract:** [sync-contract.md](https://github.com/kbmillard/skyview-dockwalk/blob/main/docs/contracts/sync-contract.md)  
**Umbrella:** [DOCKWALK.md](https://github.com/kbmillard/SkyView/blob/main/docs/products/DOCKWALK.md)

---

## Summary (2026-05-17)

DockWalk iOS is on **internal TestFlight** against **Railway production**. Kyle confirmed install after accepting the **DockStockers** internal invite (same Apple ID as App Store Connect). **LastLeg** TestFlight is unrelated — both apps can run side by side.

| Milestone | Status |
|-----------|--------|
| Phase 1C consumer (putaway list + batch sync replay) | **Shipped** (`906405d`) |
| App icon 1024×1024 | **Shipped** (`dockwalkios.png` → `AppIcon.appiconset`) |
| TestFlight **0.1.0 (1)** | **Uploaded + internal testing** |
| Export compliance | Answered in Connect; **`ITSAppUsesNonExemptEncryption = false`** in Info.plist for **next** build |
| Device QA | Today / Receive / More flows OK on TestFlight build |

**App Store Connect**

- **App:** DockWalk · bundle **`io.skyprairie.dockwalk`** (not `.tests`)
- **SKU:** internal Connect ID only (e.g. `dockwalk`) — not warehouse SKU
- **Internal group:** DockStockers
- **API:** `https://dockwalk-api-production.up.railway.app` (default in app)

**Repeat upload (CLI)**

```bash
cd apps/ios/dockwalk
xcodebuild -project DockWalk.xcodeproj -scheme DockWalk -configuration Release \
  -destination 'generic/platform=iOS' -archivePath build/DockWalk.xcarchive archive \
  DEVELOPMENT_TEAM=5RP4DB2THP CODE_SIGN_STYLE=Automatic -allowProvisioningUpdates
xcodebuild -exportArchive -archivePath build/DockWalk.xcarchive \
  -exportPath build/export -exportOptionsPlist ExportOptions.plist -allowProvisioningUpdates
```

Bump **`CURRENT_PROJECT_VERSION`** / `CFBundleVersion` before each new TestFlight build.

---

## API base URLs

| Target | URL |
|--------|-----|
| **Railway production (iOS QA default)** | **https://dockwalk-api-production.up.railway.app** |
| Local (Simulator) | `http://localhost:8790` |

**More → API connection** — presets, Save & Test, **Reset to Railway QA** / **Reset to local API**.

---

## Supabase split (do not conflate)

| Project | Ref | Use on iOS |
|---------|-----|------------|
| Service (API) | `egasxwpnutwrqivwmufm` | **Never** — no service-role key on device |
| iOS client | `jllqgothyavoqvhugrvf` | App Connect / client SDK only (if used later) |

**Receiving writes:** Railway API only. No direct Supabase inserts from iOS.

---

## iOS-only status

| Area | Status |
|------|--------|
| **Receive** | Appointments → shipments → lines → **Receive 1** / custom qty |
| **Offline queue** | Full payload + `idempotency_key` |
| **Batch replay** | `POST /api/sync/events` — `accepted` / `duplicate` dequeue |
| **Auto-replay** | **More → Sync** (default **OFF**) |
| **Manual replay** | **More → Debug** |
| **Putaway** | **More → Putaway tasks** — read-only list + detail; shipment **View putaway tasks** |
| **Audit** | **More → Activity → Audit events** |
| **TestFlight** | **0.1.0 (1)** internal — **DockStockers** |
| **Scanner / AI / payments / auth** | **OFF** |
| **Task assign / complete** | **OFF** (API read-only in 1C) |

---

## Phase 1C + TestFlight delivery (2026-05-17)

**Backend (sibling `skyview-dockwalk`, commit `017eb54` noted earlier)**

- `POST /api/sync/events` — batch receiving replay
- `GET /api/tasks?task_type=putaway` — **2** dev tasks on Railway (ASN-DEV-001)

**iOS (`906405d` … `58cf27a`)**

- Putaway list/detail, status filters, pagination
- Batch sync replay in `ReceivingEventReplayCoordinator`
- App icon + `ExportOptions.plist`
- `ITSAppUsesNonExemptEncryption` in Info.plist

**Key paths**

- `Putaway/PutawayTasksView.swift`, `PutawayTasksViewModel.swift`, `PutawayTaskDetailViewModel.swift`
- `Networking/WarehouseTaskModels.swift`, `SyncBatchModels.swift`
- `Persistence/SyncBatchReplayEngine.swift`, `ReceivingEventReplayCoordinator.swift`
- `Resources/Assets.xcassets/AppIcon.appiconset/`, `ExportOptions.plist`

**Validation (last full unit run)**

- `xcodebuild test` — **33 tests** passed (optional; day-to-day use **build** or archive only)

---

## Phase 1B (prior)

Inbound lines, receiving POST, offline queue, audit list, Railway QA defaults.

---

## Suggested next iOS work

| Priority | Work |
|----------|------|
| P1 | TestFlight **build 2** with encryption plist (skip Connect quiz) |
| P2 | Live scanner |
| P3 | Putaway assign/complete when API adds writes |
| P4 | Auth / mobile session |

---

## Cursor

Backend: **ARCHITECT_RECAP** + **api-foundation** + **sync-contract**. iOS: **this file**. **`DOCKWALK.md`** umbrella snapshot is manual.
