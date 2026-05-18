# DockWalk iOS — service handoff

**Last updated:** 2026-05-17 (TestFlight **0.1.0 (6)** uploaded — scanner-toggle reset on new build; `11efe6c`)

**Canonical backend:** [ARCHITECT_RECAP.md](https://github.com/kbmillard/skyview-dockwalk/blob/main/docs/architecture/ARCHITECT_RECAP.md)  
**API contract:** [api-foundation.md](https://github.com/kbmillard/skyview-dockwalk/blob/main/docs/contracts/api-foundation.md)  
**Sync contract:** [sync-contract.md](https://github.com/kbmillard/skyview-dockwalk/blob/main/docs/contracts/sync-contract.md)  
**Umbrella:** [DOCKWALK.md](https://github.com/kbmillard/SkyView/blob/main/docs/products/DOCKWALK.md)

---

## Agent bootstrap (next prompt)

**Read order (before editing):**

1. Umbrella [DOCKWALK.md](https://github.com/kbmillard/SkyView/blob/main/docs/products/DOCKWALK.md) (product context; manual snapshot)
2. [ARCHITECT_RECAP.md](https://github.com/kbmillard/skyview-dockwalk/blob/main/docs/architecture/ARCHITECT_RECAP.md) — backend truth
3. [api-foundation.md](https://github.com/kbmillard/skyview-dockwalk/blob/main/docs/contracts/api-foundation.md) · [sync-contract.md](https://github.com/kbmillard/skyview-dockwalk/blob/main/docs/contracts/sync-contract.md)
4. **This file** — iOS-only truth

**Repo layout**

| What | Path |
|------|------|
| Git root / Cursor workspace | `skyview-ios-dockwalk` |
| Xcode project | `apps/ios/dockwalk/DockWalk.xcodeproj` |
| Regenerate project after new Swift files | `cd apps/ios/dockwalk && xcodegen generate` |

**Do not edit** sibling `skyview-dockwalk` (API/service) unless the task explicitly says so. Service is **green on Railway prod** — do not re-debug or replace API behavior for normal iOS work.

**Railway QA defaults (device config)**

| Key | UUID |
|-----|------|
| Org | `00000000-0000-4000-8000-000000000001` |
| Facility | `00000000-0000-4000-8000-000000000010` |

**Operator**

- Validate with **`xcodebuild build`** or **archive** — do **not** run `xcodebuild test` unless Kyle asks.
- Commit + push to `origin` when a coherent chunk is done (unless asked not to).
- **Ship / Inventory tabs** are still placeholders — don’t assume full WMS is done.

**Paste block for a new chat**

```text
DockWalk iOS agent. Repo: skyview-ios-dockwalk. Read docs/SERVICE_HANDOFF.md + linked backend contracts; do not edit skyview-dockwalk unless asked. Railway prod is live. TestFlight 0.1.0 (6); scanner OFF each new build; Debug toggle for per-device QA only. Build only unless tests requested. AI / payments / auth / direct Supabase / task cancel OFF.
```

---

## Summary (2026-05-17)

DockWalk iOS is on **internal TestFlight** against **Railway production**. Kyle confirmed install after accepting the **DockStockers** internal invite (same Apple ID as App Store Connect). **LastLeg** TestFlight is unrelated — both apps can run side by side.

| Milestone | Status |
|-----------|--------|
| Phase 1C consumer (putaway list + batch sync replay) | **Shipped** (`906405d`) |
| App icon 1024×1024 | **Shipped** (`dockwalkios.png` → `AppIcon.appiconset`) |
| TestFlight **0.1.0 (1)** | Superseded by build **2** (still installable until expired) |
| TestFlight **0.1.0 (2)** | Superseded by build **3** (plist-only hygiene) |
| TestFlight **0.1.0 (3)** | Superseded by build **4** — Phase **1D** + **1E**; smoke **passed** |
| TestFlight **0.1.0 (4)** | Superseded by build **5** |
| TestFlight **0.1.0 (5)** | Superseded by build **6** |
| TestFlight **0.1.0 (6)** | **Uploaded** 2026-05-17 — scanner-toggle reset on new `CFBundleVersion` (`11efe6c`) |
| Export compliance | **`ITSAppUsesNonExemptEncryption = false`** (build **6** archive) |
| Device QA | Build **3** smoke **passed**; build **6** smoke after Connect processing |
| IA/copy cleanup | In builds **4+** (`c8e53f4`) |
| Phase **1F** scanner | In builds **4+** (`ce4dd48`); compile flag **off** |
| Phase **1F.1** runtime toggle | Builds **5+**; **6** resets toggle **off** on first launch of new build |

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

## Latest delivery — TestFlight 0.1.0 (6) (2026-05-17)

**Scope:** Scanner-toggle **safety / hygiene** release only. Includes **`11efe6c`**: on first launch of a new `CFBundleVersion`, internal scanner toggle resets **off** (fixes build **5** carrying `UserDefaults` across TestFlight update). **No** new product features, service changes, or scanner workflow expansion.

| Item | Detail |
|------|--------|
| Marketing version | **0.1.0** (unchanged) |
| Build | **6** |
| Bundle ID | `io.skyprairie.dockwalk` |
| Compile scanner flag | `liveScannerEnabled` **false** |
| Default for testers | Scanner **hidden** (no Scanner Lab / scan buttons) |
| Per-device QA | More → **Open debug panel** → **Enable scanner on this device** |
| Toggle persistence | **Within same build** only; **new build → off** on first launch |
| Camera plist | `NSCameraUsageDescription` present |
| Export compliance | `ITSAppUsesNonExemptEncryption = false` |
| Archive | **ARCHIVE SUCCEEDED** |
| Export/upload | **EXPORT SUCCEEDED** — Upload succeeded (processing) |

**Still OFF:** AI/Gemini, OCR cloud, image upload, payments, auth, direct Supabase, task cancel. No backend/service repo edits.

**Why build 6:** Build **5** correctly persisted Debug scanner toggle across TestFlight update; build **6** ensures every new build starts with scanner off until explicitly re-enabled in Debug.

---

## TestFlight 0.1.0 (5) (2026-05-17)

Superseded by build **6**. Phase **1F.1** Debug toggle; toggle could persist across update from prior QA.

---

## Phase 1F.1 — Runtime internal scanner toggle

| Item | Detail |
|------|--------|
| Compile flag | `FeatureFlags.liveScannerEnabled` stays **`false`** |
| Runtime toggle | Debug panel → **Enable scanner on this device** |
| Persistence | `DockWalk.internalScannerEnabled` — survives restarts; **resets off** on each new `CFBundleVersion` (TestFlight build bump) |
| Effective gate | `scannerPreferences.isScannerActive` (= compile **or** internal) |
| More → Feature flags | Shows **Scanner on device** effective state |
| TestFlight | **0.1.0 (6)** — toggle resets off on new build; Debug-only enable |

**Do not** deepen Receive/Putaway scanner workflow until QA passes on device camera.

---

## Phase 1F scanner spike (reference)

**Scope:** Native barcode foundation only. **No** Gemini, OCR cloud, image upload, payments, auth, Supabase client writes, or new Railway routes.

| Item | Detail |
|------|--------|
| Feature flag | `FeatureFlags.liveScannerEnabled` — default **`false`** |
| When **off** | No scanner buttons on Today / Receive / Ship / Inventory; no Scanner Lab link |
| When **on** | **More → Modules → Scanner Lab**; optional **Scan line** on shipment detail; **Scan label** on putaway detail (context only) |
| Framework | **AVFoundation** metadata (`AVCaptureMetadataOutput`) |
| Types | QR, Code 128, Code 39, EAN-13, EAN-8, UPC-E, PDF417 |
| Permission | `NSCameraUsageDescription` in `Info.plist` |
| Simulator | Manual entry fallback; camera preview hidden when unavailable |
| Dedup | ~2s cooldown per identical scan value |
| Receive integration | Scan → match line **SKU** → **Receive 1** |
| Putaway integration | Scan → display scanned code context only (no auto-complete) |

**Build:** `xcodegen generate` + `xcodebuild -project DockWalk.xcodeproj -scheme DockWalk -destination 'generic/platform=iOS' build CODE_SIGNING_ALLOWED=NO` → **BUILD SUCCEEDED** (2026-05-17).

**Enable scanner QA:** Debug → **Enable scanner on this device** (preferred). Compile-time: set `liveScannerEnabled = true` + rebuild (only for dev builds).

---

## IA/copy cleanup (post–TestFlight 3 smoke)

**Scope:** Navigation and copy only — **no** API/behavior changes, **no** new TestFlight build.

| Change | Detail |
|--------|--------|
| Putaway entry | **More → Modules → Putaway tasks** only (removed duplicate under Activity) |
| Activity | **Audit events** only; footer no longer mentions putaway |
| Putaway copy | Accurate online + offline queue messaging (list + task detail) |
| Sync empty state | **No queued actions.** when queue is empty |

**Shipped in TestFlight build 4.**

---

## TestFlight 0.1.0 (3) (2026-05-17)

**Scope:** Ship **Phase 1D + 1E** to internal TestFlight. **No** scanner, AI, payments, auth, direct Supabase, or task cancel.

| Included in build | Behavior |
|-------------------|----------|
| **Phase 1D** | Putaway assign / start / block / complete (online direct routes) |
| **Phase 1E** | Offline `task_action` queue + `POST /api/sync/events` batch replay |
| **Phase 1C** | Receive offline queue + receiving batch replay (unchanged) |

| Step | Result |
|------|--------|
| `ITSAppUsesNonExemptEncryption` | `false` in `Info.plist` — confirmed in archived app (`CFBundleVersion` **3**) |
| Version | Marketing **0.1.0** · build **3** |
| Bundle ID | `io.skyprairie.dockwalk` (unchanged) |
| Archive | **ARCHIVE SUCCEEDED** |
| Export + upload | **EXPORT SUCCEEDED** · **Upload succeeded** (`ExportOptions.plist` → `upload`) |
| Local IPA | Upload destination consumed package; no long-lived IPA kept in repo (standard CLI upload flow) |
| Export compliance quiz | Expect **skipped** (plist `ITSAppUsesNonExemptEncryption` = false) |

**Git:** `ca70c40` + build bump commit on `main`

**Still off:** scanner, AI, payments, auth, direct Supabase (egas), task cancel UI.

**After Connect processing:** enable build **3** on **DockStockers** and run device smoke (checklist below).

**Kyle — App Store Connect checklist (build 3):**

1. Wait until **0.1.0 (3)** finishes **Processing** in TestFlight.
2. Enable build **3** for internal group **DockStockers** (or confirm group uses latest build).
3. Export-compliance quiz should **not** appear (`ITSAppUsesNonExemptEncryption` = false).
4. **Putaway (online):** assign → start → block → complete against Railway prod dev tasks.
5. **Putaway (offline):** airplane mode or bad network → action shows **Queued for sync** → restore network → **More → Sync** manual or auto-replay → task updates on server.
6. **Receive:** receive line still queues/replays as before.
7. **Activity:** audit list still loads.
8. **More → Sync:** queued receiving + task-action counts; replay message after manual replay in Debug.

### Build 2 verification pass (2026-05-17, commit `11b7734`)

| Check | Result |
|-------|--------|
| Git | Clean except `dockwalkios.jpeg` — **gitignored** (do not commit; app icon = `AppIcon.appiconset`) |
| Repo build metadata | `CFBundleVersion` **2**, `ITSAppUsesNonExemptEncryption` **false** in target `Info.plist` |
| Local `xcodebuild build` | **BUILD SUCCEEDED** (no new archive/upload) |
| App Store Connect API from agent | **Not queried** (no ASC issuer in local fastlane env) |

**Kyle — confirm in App Store Connect (TestFlight):**

1. **0.1.0 (2)** finished **Processing** (not still “Processing”)
2. Export-compliance quiz **did not appear** (expected with plist `false`)
3. Build **2** enabled for **DockStockers** (or group uses latest internal build)
4. Optional device smoke on build 2: Railway API test, Receive, Putaway, Activity

Record outcomes here when known; then next iOS feature work is **scanner** (see table below).

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
| **Putaway** | List + detail; **assign / start / block / complete** |
| **Putaway online** | Direct `POST /api/tasks/:id/*` (happy path) |
| **Putaway offline** | Transport failure → **`task_action` queue** → batch replay; **409/400/404** not queued |
| **Task batch replay** | `POST /api/sync/events` — `accepted` / `duplicate` dequeue; **`rejected` stays queued** |
| **Audit** | **More → Activity → Audit events** |
| **TestFlight** | **0.1.0 (3)** uploaded — **DockStockers** (enable after processing) |
| **Scanner / AI / payments / auth** | **OFF** |
| **Task cancel** | **OFF** (no API route exposed in app) |

---

## Latest delivery — Phase 1E offline task-action queue (2026-05-16)

**Scope:** Queue putaway task actions on transport failure; replay via **`task_action`** batch sync. Receiving replay unchanged.

| Path | Behavior |
|------|----------|
| Online | Direct assign / start / block / complete (`org_id` + `idempotency_key` + `device_id`) |
| Offline / transport | Enqueue `task_action` with **same** `idempotency_key` as failed direct call |
| Replay | `POST /api/sync/events` — mixed batches with receiving events (up to **50** events) |
| `accepted` / `duplicate` | Dequeue task action |
| `rejected` | Keep queued; store `lastError` on queue row |
| `409` on direct route | No queue; refresh task |
| Auto-replay | **More → Sync** (default **OFF**) — receiving + task actions when enabled |

**Files:** `Networking/TaskActionSyncModels.swift`, `SyncBatchModels.swift`, `Persistence/SyncBatchReplayEngine.swift`, `OfflineSyncStore.swift`, `ReceivingEventReplayCoordinator.swift`, `Putaway/PutawayTaskDetailViewModel.swift`, `Settings/SettingsView.swift`, `Debug/DebugPanelView.swift`, `DockWalkTests/DockWalkFoundationTests.swift`

**Build:** `xcodegen generate` + `xcodebuild build CODE_SIGNING_ALLOWED=NO` → **BUILD SUCCEEDED** (no TestFlight / version bump)

---

## Phase 1D putaway task actions (2026-05-16)

**Scope:** Online task writes only. **No** product changes to receive replay, scanner, auth, or Supabase.

| API (Railway) | iOS |
|---------------|-----|
| `POST /api/tasks/:id/assign` | Assign (pending, blocked) |
| `POST /api/tasks/:id/start` | Start (pending, assigned, blocked) |
| `POST /api/tasks/:id/block` | Block sheet — preset `reason_code` + details |
| `POST /api/tasks/:id/complete` | Confirm dialog → `quantity_completed` default **1** (shows task qty context) |

- List filters: **all**, pending, assigned, in_progress, **blocked**, completed, cancelled.
- Dock-friendly **PrimaryActionButton** actions (“Assign to me”, “Resume” when blocked).
- Fresh `ios-task-*` idempotency key per user tap; **same key** retained on transport retry for that tap.
- `idempotent: true` → success banner, not error.
- **409** `invalid_transition` → readable message + refresh task + list.
- Block presets: `location_blocked`, `product_damaged`, `missing_item`, `other`.
- `in_progress`: **Complete** then **Block**.
- **Cancel** not shown (no dedicated cancel route).
- Phase 1E added offline queue (supersedes “online only” for transport failures).

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
| P1 | Enable build **6** on DockStockers; smoke stable flows (scanner off after update) |
| P2 | Scanner device QA via Debug toggle on build **6** |
| P3 | Deeper Receive/Putaway scanner workflow (after camera QA) |
| P4 | Auth / mobile session |
| P5 | Task cancel when API adds route |

---

## Cursor

Backend: **ARCHITECT_RECAP** + **api-foundation** + **sync-contract**. iOS: **this file**. **`DOCKWALK.md`** umbrella snapshot is manual.
