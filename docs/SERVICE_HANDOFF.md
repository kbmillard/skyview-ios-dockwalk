# DockWalk iOS — 

**Last updated:** 2026-05-18 (Phase 2 prototype alignment — scanner lock chips, floor sheets, Today layout; build **0.1.0 (8)** still current on TestFlight)

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


| What                                     | Path                                        |
| ---------------------------------------- | ------------------------------------------- |
| Git root / Cursor workspace              | `skyview-ios-dockwalk`                      |
| Xcode project                            | `apps/ios/dockwalk/DockWalk.xcodeproj`      |
| Regenerate project after new Swift files | `cd apps/ios/dockwalk && xcodegen generate` |


**Do not edit** sibling `skyview-dockwalk` (API/service) unless the task explicitly says so. Service is **green on Railway prod** — do not re-debug or replace API behavior for normal iOS work.

**Railway QA defaults (device config)**


| Key      | UUID                                   |
| -------- | -------------------------------------- |
| Org      | `00000000-0000-4000-8000-000000000001` |
| Facility | `00000000-0000-4000-8000-000000000010` |


**Operator**

- Validate with `**xcodebuild build`** or **archive** — do **not** run `xcodebuild test` unless Kyle asks.
- Commit + push to `origin` when a coherent chunk is done (unless asked not to).
- **Ship / Inventory** have full workflow structure with job cards and stable foundation data — live API integration & write operations still pending.

**Paste block for a new chat**

```text
DockWalk iOS agent. Repo: skyview-ios-dockwalk. Read docs/SERVICE_HANDOFF.md + linked backend contracts; do not edit skyview-dockwalk unless asked. Railway prod is live. Tabs: Today / Receiving / Inventory / Putaway / Shipping (Inventory center). TestFlight 0.1.0 (8). Prototype-aligned Today + ScannerLockChip on work modes + floor bottom sheets (exception, scan confirm, dock door). Scanner Debug-gated. Build only unless tests requested. AI / payments / auth / direct Supabase / task cancel OFF.
```

---

## Summary (2026-05-18)

DockWalk iOS is on **internal TestFlight** against **Railway production**. Kyle confirmed install after accepting the **DockStockers** internal invite (same Apple ID as App Store Connect). **LastLeg** TestFlight is unrelated — both apps can run side by side.


| Milestone                                            | Status                                                                                              |
| ---------------------------------------------------- | --------------------------------------------------------------------------------------------------- |
| Phase 1C consumer (putaway list + batch sync replay) | **Shipped** (`906405d`)                                                                             |
| App icon 1024×1024                                   | **Shipped** (`dockwalkios.png` → `AppIcon.appiconset`)                                              |
| TestFlight **0.1.0 (1)**                             | Superseded by build **2** (still installable until expired)                                         |
| TestFlight **0.1.0 (2)**                             | Superseded by build **3** (plist-only hygiene)                                                      |
| TestFlight **0.1.0 (3)**                             | Superseded by build **4** — Phase **1D** + **1E**; smoke **passed**                                 |
| TestFlight **0.1.0 (4)**                             | Superseded by build **5**                                                                           |
| TestFlight **0.1.0 (5)**                             | Superseded by build **6**                                                                           |
| TestFlight **0.1.0 (6)**                             | Superseded by build **7**                                                                           |
| TestFlight **0.1.0 (7)**                             | Superseded by build **8**                                                                           |
| TestFlight **0.1.0 (8)**                             | **Uploaded** 2026-05-18 — Spec tabs: Today / Receiving / Inventory (center) / Putaway / Shipping (`3028755`) |
| Export compliance                                    | `**ITSAppUsesNonExemptEncryption = false`** (build **7** archive)                                   |
| Device QA                                            | Build **3** + **6** smoke **passed** (Receive, Putaway complete/block, Activity, Sync; scanner off) |
| IA/copy cleanup                                      | In builds **4+** (`c8e53f4`)                                                                        |
| Phase **1F** scanner                                 | In builds **4+** (`ce4dd48`); compile flag **off**                                                  |
| Phase **1F.1** runtime toggle                        | Builds **5+**; **6** resets toggle **off** on first launch of new build                             |
| Phase **1G** operational shell                       | In build **7** — Putaway tab, Today command center, More = admin only                               |
| Phase **1H** WMS shell buildout                      | In build **7** — Inventory & Ship feel real; Today improved; no backend changes                      |
| Phase **1I** WMS command center (Phase 1)            | In build **7** (`0fc4a00`) — Inbound workflow, dock doors, putaway queue, stable data behavior      |
| Phase **2** Ship & Inventory deep integration       | In build **7** (`c9a84c2`) — Full workflow, job cards, scanner integration, Today summaries         |


**App Store Connect**

- **App:** DockWalk · bundle `**io.skyprairie.dockwalk`** (not `.tests`)
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

Bump `**CURRENT_PROJECT_VERSION**` / `CFBundleVersion` before each new TestFlight build.

---

## Latest delivery — Phase 2b: Prototype visual alignment (2026-05-18)

**Scope:** Align native UI to HTML floor prototype — scanner lock contract, work-mode chips, bottom sheets, Today command center layout. **No** auth, payments, Gemini, Supabase client, backend routes, or TestFlight upload. Build still **0.1.0 (8)**.

### Scanner lock contract

- `ScannerMode` enum: `globalInventory`, `load(loadId:)`, `putawayTask(taskId:)`, `shipment(shipmentId:)`
- `ScannerLockChip` visible on Inventory (global), Receiving load detail, Putaway task detail, Shipping load detail
- Floating scan disc on `MainTabView`: Today → Inventory tab; Inventory → global scan; Receiving/Putaway/Shipping → scan confirm sheet

### Floor bottom sheets

- `ExceptionMarkingSheet`, `ScanConfirmSheet`, `DockDoorSelectorSheet` in `DesignSystem/FloorWorkSheets.swift`
- Wired on Receiving (`ShipmentDetailView`), Putaway (`PutawayTaskDetailView`), Shipping (`ShippingLoadDetailView`), Inventory quick scan

### Today command center

- Live Now banner, 2×2 overview stats, quick actions row, recent work feed (mock data from `MockWarehouseFloor`)
- DockWalk by SkyView branding; Settings/Activity via sheets (no More tab)

### Shipping work mode

- `ShippingLoadDetailView` for staged/loading orders (tap S-55120 card on Shipping tab)
- Stub outbound data includes **S-55120** (Midwest Supply, Door 2, staged)
- Navigation titles: **Receiving**, **Shipping** (was Receive / Ship)

### Build validation

```bash
cd apps/ios/dockwalk
xcodegen generate
xcodebuild -project DockWalk.xcodeproj -scheme DockWalk \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' build
# BUILD SUCCEEDED
```

---

## Previous delivery — Phase 2: Ship & Inventory Deep Integration (2026-05-18)

**Scope:** Ship and Inventory workflow expansion with dock-worker friendly UX. **No** auth, payments, Gemini, direct Supabase, task cancel, new backend routes, TestFlight upload, or version bump. Uses stable local foundation data. All existing flows (Receive, Putaway, offline queue) remain working.

### Ship/Outbound deep integration

**Full workflow model:**
- `OutboundOrderStatus` expanded: `readyToPick`, `picking`, `picked`, `staged`, `loading`, `shipped`
- Job cards now include: order number, customer, line count, carton count, priority (standard/urgent), ship date, assigned worker, door assignment
- `OutboundOrder` model expanded with: `orderNumber`, `lineCount`, `priority`, `shipDate`, `assignedTo`
- New `OrderPriority` enum with display styling
- New `OutboundWorkflowGroup` for organizing orders by status

**ShippingHomeView restructure:**
- **Workflow summary** — ready to pick, picking, loading counts in unified card
- **Ready to pick** — orders awaiting assignment, job card format
- **Picking** — active picking + picked orders grouped
- **Staged for loading** — orders staged at dock doors
- **Loading now** — active loading operations
- **Job cards** show: order #, customer, priority badge (urgent), line count, carton count, door, assigned worker, ship date
- Scanner integration: toolbar button (top-right) when scanner enabled — feels accessible, not hidden
- Foundation notice at bottom explaining stable local data, pending full write operations
- **No fake writes** — all data from `OutboundViewModel` stub data (6 orders across all statuses)

**OutboundViewModel expansion:**
- Computed properties: `readyToPickOrders`, `pickingOrders`, `pickedOrders`, `stagedOrders`, `loadingOrders`, `shippedOrders`, `activeWorkOrders`
- `workflowGroups` array for Today integration
- Stub data includes realistic: order numbers (SO-####), priorities, ship dates, assignments

### Inventory deep integration

**InventoryHomeView restructure:**
- **Inventory summary** — SKU count, total on-hand units, reserved units in unified card
- **Quick actions** — location lookup as prominent card (not buried)
- **Search inventory** — enhanced with result count chip
- **On-hand items** — improved card layout with clearer on-hand/reserved/available breakdown
- **Recent movement** — shows SKU transfers between locations
- **Cycle count** — structured cycle count tasks display
- Scanner integration: toolbar button (top-right) when scanner enabled — consistent with Ship
- Foundation notice at bottom explaining stable local data
- **No fake writes** — all data from stub `InventoryViewModel`

**InventoryViewModel expansion:**
- New computed properties: `totalOnHandUnits`, `totalReservedUnits`, `totalAvailableUnits`
- Search result count for filtered items
- Stub data unchanged (3 items, 2 movements, 2 cycle count tasks)

### Today integration

**Outbound section:**
- Changed from placeholder text to actual summary card
- Shows: ready to pick count, picking count, loading count
- Tappable card navigates to Ship tab
- Reflects real outbound state from dashboard

**Inventory section:**
- Changed from simple navigation link to summary card
- Shows: SKU count, total on-hand units
- Tappable card navigates to Inventory view
- Reflects real inventory state from dashboard

**TodayDashboardViewModel expansion:**
- New properties: `readyToPickCount`, `pickingCount`, `loadingCount` (outbound)
- New properties: `inventorySkuCount`, `inventoryTotalUnits` (inventory)
- `loadFoundationSummaryData()` populates from `OutboundViewModel` and `InventoryViewModel` stub data
- Data loads once on init, stable across tab switches

### Scanner integration philosophy

**Toolbar placement:**
- Ship and Inventory now use toolbar button (top-right) instead of inline button
- Feels "close at hand" like a camera — always visible when scanner enabled
- Consistent positioning across all work surfaces
- Still uses `FeatureFlags.liveScannerEnabled` (compile-time) + `ScannerPreferencesStore` (runtime toggle)
- `dismissScannerSheetWhenInactive` modifier ensures scanner dismisses when toggle disabled

**Scanner is not a feature to the worker** — it's a tool. The feature is "fewer steps" and "knowing what needs done next."

### Stable data behavior

- No API routes added: `.inventoryItems` and `.outboundOrders` endpoints defined in `APIEndpoint.swift` but not implemented in `APIClient.swift`
- All Ship data: stable stub data from `OutboundViewModel` (6 orders)
- All Inventory data: stable stub data from `InventoryViewModel` (3 items)
- Today summaries: loaded once on init, no tab-switch mutations
- No refresh storms, no accidental server state changes
- Pull-to-refresh works normally for live data (appointments, tasks)

### What stayed off

- AI/Gemini inspection routes
- Payments
- Auth
- Direct Supabase client calls
- Task cancel feature
- New backend routes (endpoints stubbed only)
- Fake writes (no inventory decrement, no pick/stage/ship writes, no closeout)
- Label/BOL generation
- TestFlight upload
- Version/build bump

### Build validation

```bash
cd apps/ios/dockwalk
xcodegen generate  # Succeeded
xcodebuild -project DockWalk.xcodeproj -scheme DockWalk \
  -destination 'generic/platform=iOS' build CODE_SIGNING_ALLOWED=NO
# BUILD SUCCEEDED (4.9s)
```

### Files changed

**New:**
- None (all changes to existing files)

**Modified:**
- `DockWalk/Outbound/OutboundModels.swift` — expanded `OutboundOrderStatus` to 6 states, added `OrderPriority`, `OutboundWorkflowGroup`
- `DockWalk/Outbound/OutboundViewModel.swift` — expanded with full workflow computed properties, `workflowGroups`, richer stub data (6 orders)
- `DockWalk/Outbound/ShippingHomeView.swift` — complete rebuild: workflow summary, job cards, section-by-section workflow, toolbar scanner
- `DockWalk/Inventory/InventoryViewModel.swift` — added `totalOnHandUnits`, `totalReservedUnits`, `totalAvailableUnits`
- `DockWalk/Inventory/InventoryHomeView.swift` — restructured: inventory summary card, quick actions, enhanced search, toolbar scanner, foundation notice
- `DockWalk/App/TodayDashboardViewModel.swift` — added outbound/inventory summary properties, `loadFoundationSummaryData()`
- `DockWalk/App/TodayView.swift` — rebuilt outbound and inventory sections to show real summaries instead of placeholders
- `docs/SERVICE_HANDOFF.md` — this update

**Existing flows unchanged:**
- Receive 1/custom qty — working
- Putaway assign/start/block/complete — working
- Offline task_action queue + batch replay — working
- Activity log — working
- Sync status — working
- Scanner flag behavior (compile + runtime toggle) — working

---

## Phase 1I delivery — WMS command center rebuild (Phase 1) (2026-05-18)

**Scope:** Today command center restructure only. **No** Ship/Inventory deep rebuild, auth, payments, Gemini, Supabase client, TestFlight upload, or backend changes. Phase 2 continued Ship and Inventory integration.

### WMS command center structure

Today is now organized around proper WMS workflow sections:

**Sections:**
1. **Inbound** — workflow status groups (scheduled, checked-in, staged, receiving)
2. **Dock doors** — open/occupied status foundation
3. **Putaway** — queue groups by status (staged, assigned, in-progress, blocked, complete)
4. **Outbound** — foundation preview (deeper integration in Phase 2)
5. **Inventory** — lookup entry point
6. **System** — Sync, Activity, Scanner Lab (when enabled)

### Inbound workflow model

Inbound loads now display by operational status:
- **Scheduled** — planned loads not yet arrived
- **Checked In** — loads arrived onsite
- **Staged** — loads assigned to dock door
- **Receiving** — active receiving in progress

Data sourced from `GET /api/appointments` with status inference from API status field.

Each group shows count and links to Receive tab.

### Dock door foundation

Dock door status dashboard shows:
- **Open doors** — available for assignment
- **Occupied doors** — active receiving

Uses stable local foundation data (no live API route yet). 4 doors shown: 1 occupied (APT-1002), 3 open.

No fake writes. Intentional preview structure for operational awareness.

### Putaway queue grouping

Putaway tasks grouped by workflow status:
- **Staged / Pending** — tasks awaiting assignment
- **Assigned** — tasks assigned to worker
- **In Progress** — active putaway work
- **Blocked** — tasks with issues
- **Complete** — finished tasks

Data sourced from existing `GET /api/tasks?task_type=putaway` with grouping by status field.

Shows top 4 groups on Today. Full queue on Putaway tab unchanged.

Offline task-action queue alert prominent when count > 0.

### Stable data behavior

Fixed tab-switch data stability issues:
- Dashboard loads once on first appearance, then only on pull-to-refresh
- Uses `hasInitiallyLoaded` flag to prevent re-fetch on every tab switch
- Caches data on error if previously loaded successfully
- No automatic mutations on tab appearance
- Explicit user actions (pull-to-refresh, tap) trigger refreshes

View model expansion:
- `TodayDashboardViewModel` now processes workflow groups
- Returns `inboundGroups`, `putawayGroups`, `dockDoors`
- Preserves existing data on error after initial load

### Files created

- `DockWalk/App/InboundWorkflowModels.swift` — InboundStatus, InboundLoad, InboundLoadGroup, DockDoorStatus, PutawayQueueGroup, PutawayQueueStatus models

### Files modified

- `DockWalk/App/TodayView.swift` — complete rebuild with WMS sections
- `DockWalk/App/TodayDashboardViewModel.swift` — expanded to process workflow groups, stable caching behavior

### Unchanged behavior

- Receive flow still works (appointments → shipments → lines → receive)
- Putaway flow still works (assign/start/block/complete + offline queue)
- Offline queue + batch replay unchanged
- Scanner flag gating unchanged
- Activity/Sync unchanged
- All existing tabs and navigation preserved

### Deferred to Phase 2

- Ship screen deeper workflow integration (pick/stage/load sections)
- Inventory screen deeper integration (live API wiring if available)
- Outbound write operations
- Inventory adjustment writes
- Dock door assignment writes

**Build:** `xcodegen generate` + `xcodebuild build CODE_SIGNING_ALLOWED=NO` → **BUILD SUCCEEDED** (2026-05-18).

**TestFlight:** Still **0.1.0 (7)** — Phase 1I on `main` not yet bundled.

---

## Phase 1H WMS shell buildout (2026-05-18)

**Superseded by Phase 1I command center rebuild.**

**Scope:** iOS UI/UX buildout only. **No** API routes, auth, payments, Gemini, Supabase client, TestFlight upload, or backend changes.

### Today command center improvements

- Appointment count now uses items count directly (no pagination for appointments)
- Putaway task count still uses pagination total
- Improved "Inventory & outbound" section naming
- Better operational context for dock work vs preview features

### Inventory surface — real module feel

**New files:**
- `DockWalk/Inventory/LocationLookupView.swift` — location-based item lookup

**Enhanced:**
- Location lookup card (tap to search by bin/aisle/zone)
- Improved search field with header
- Better empty states for search results
- Recent movement section (links to Activity audit trail)
- Enhanced item cards with on-hand/reserved/available breakdown
- Cycle count section with intentional empty state

**Models:**
- Added `InventoryMovement` struct (SKU, from/to locations, quantity, timestamp)
- ViewModel now includes `recentMovements` preview data

**UX:**
- Scanner button only when scanner is active
- Clear foundation banner explaining preview vs full control
- Location lookup sheet modal
- Visual hierarchy: command → search → items → movement → cycle count

### Ship/Outbound surface — real operational structure

**Enhanced:**
- Pick, Stage, Load operational command cards
- Summary metrics: active loads, staged count, picking count
- Sectioned by operational stage: Loading / Picking & Staged / Closeout
- Better empty states for each section
- Door and carton counts for each order

**ViewModel:**
- Computed properties for filtered lists (`loadingOrders`, `pickingAndStagedOrders`, `readyToCloseOrders`)
- Counts for summary cards (`activeLoadsCount`, `stagedCount`, `pickingCount`)

**UX:**
- Scanner button only when scanner is active
- Intentional empty states explaining what will appear
- Clear status chips for order states
- Foundation banner explaining preview structure

### Receive & Putaway — unchanged behavior

- No changes to Receive or Putaway workflows
- Offline queue, batch replay, scanner gating unchanged

### Scanner — remains feature-controlled

- Consistent scanner button behavior across Inventory, Ship, Receive, Putaway
- Only shown when `scannerPreferences.isScannerActive`
- Scanner Lab still available from Today when enabled

### Backend & API — zero changes

- No new API routes
- No changes to existing endpoints
- No Supabase migrations
- No Railway service changes

**Build:** `xcodegen generate` + `xcodebuild build CODE_SIGNING_ALLOWED=NO` → **BUILD SUCCEEDED** (2026-05-18).

**TestFlight:** Shipped in **0.1.0 (7)** (2026-05-18).

---

## Phase 1G operational app shell (2026-05-18)

**Superseded by Phase 1H.**

**Original scope:** iOS navigation / IA only. **No** API routes, auth, payments, Gemini, Supabase client, or TestFlight upload.

**Scope:** iOS navigation / IA only. **No** API routes, auth, payments, Gemini, Supabase client, or TestFlight upload.

### Tab bar (5)


| Tab         | Role                                                                                 |
| ----------- | ------------------------------------------------------------------------------------ |
| **Today**   | Command center — cards for Receive, Putaway, Sync, Activity; Ship/Inventory previews |
| **Receive** | Appointments → shipments → lines (unchanged API behavior)                            |
| **Putaway** | First-class putaway list + task detail (was buried under More → Modules)             |
| **Ship**    | Outbound foundation preview (intentional placeholder)                                |
| **More**    | Facility, API, Sync, Activity audit, Debug, feature flags; Scanner Lab when enabled  |


**Inventory** is not a tab (5-tab limit). Reach it from **Today → Inventory** (foundation preview).

### Moved out of More

- **Putaway tasks** → **Putaway** tab
- Operational entry points → **Today** cards

### Still in More

- API connection, Sync (+ auto-replay), Activity audit
- Debug panel (+ manual replay, scanner QA toggle)
- Feature flags, facility info
- Scanner Lab (only when `isScannerActive`)
- Exceptions / Inspection stubs under Debug

### Today dashboard

- Loads appointment count + putaway task total (existing list/task APIs, `limit: 1` for pagination total)
- Shows offline queue hints from `OfflineSyncStore`
- Pull to refresh

### Unchanged behavior

- Receive / putaway writes, offline `task_action` queue, batch replay, scanner flag gating

**Build:** `xcodegen generate` + `xcodebuild build CODE_SIGNING_ALLOWED=NO` → **BUILD SUCCEEDED** (2026-05-18).

**TestFlight:** Shipped in **0.1.0 (7)** (2026-05-18).

---

## TestFlight 0.1.0 (7) (2026-05-18)

**Scope:** Phase **1G** + **1H** WMS shell bundled release. Includes Putaway tab, Today command center, Inventory & Ship operational foundations with intentional structure. Scanner foundation present but controlled (compile flag **off**, runtime toggle available in Debug). **No** backend/API changes, auth, payments, Gemini, direct Supabase, or task cancel.


| Item                 | Detail                                                                |
| -------------------- | --------------------------------------------------------------------- |
| Marketing version    | **0.1.0** (unchanged)                                                 |
| Build                | **7**                                                                 |
| Bundle ID            | `io.skyprairie.dockwalk`                                              |
| Compile scanner flag | `liveScannerEnabled` **false**                                        |
| Default for testers  | Scanner **hidden** (no Scanner Lab / scan buttons)                    |
| Per-device QA        | More → **Open debug panel** → **Enable scanner on this device**       |
| Camera plist         | `NSCameraUsageDescription` present                                    |
| Export compliance    | `ITSAppUsesNonExemptEncryption = false`                               |
| Archive              | **ARCHIVE SUCCEEDED**                                                 |
| Export/upload        | **EXPORT SUCCEEDED** — Upload succeeded (processing)                  |


**Includes:**
- **Phase 1G:** Putaway first-class tab, Today command center (Receive/Putaway/Sync/Activity cards), More = admin/debug only
- **Phase 1H:** Inventory surface (location lookup, search, recent movement, cycle count structure), Ship surface (Pick/Stage/Load command cards, sectioned by operational stage), Today "Inventory & outbound" section
- **IA/copy cleanup:** Accurate queue messaging, operational entry points from Today
- **Scanner foundation:** Phase 1F + 1F.1 — AVFoundation spike, Debug runtime toggle, auto-dismiss when toggled off, build-scoped reset
- **Stable workflows:** Receive (appointments → shipments → lines), Putaway (assign/start/block/complete), offline queue + batch replay (`POST /api/sync/events`)

**Still OFF:** AI/Gemini, OCR cloud, image upload, payments, auth, direct Supabase, task cancel. No backend/service repo edits.

**Why build 7:** Bundles complete WMS shell (Phase 1G + 1H) — app now feels like an enterprise-grade warehouse system with Today hub, Receive, Putaway, Inventory preview, and Ship preview. Ready for device smoke testing before deeper feature integration.

### Build 7 device smoke checklist (Kyle)


| Area           | Test                                                                                     |
| -------------- | ---------------------------------------------------------------------------------------- |
| Today          | Command center loads appointment + putaway counts; cards link to Receive/Putaway/More    |
| Receive        | Appointments → shipments → lines → receive 1 / custom qty                                |
| Putaway        | Task list loads; tap task → assign/start/block/complete (online + offline queue)         |
| Inventory      | Preview loads; location lookup opens modal; search filters items; recent movement visible |
| Ship           | Preview loads; Pick/Stage cards visible; sectioned by Loading/Picking/Closeout           |
| Activity       | Audit events load from API                                                               |
| Sync           | Empty state / queued count; manual replay from Debug                                     |
| Scanner        | Hidden by default; Debug toggle → Scanner Lab appears on Today; toggle off → UI dismisses |
| Offline queue  | Airplane mode → receive/putaway action → **Queued for sync** → restore → replay works    |

---

## TestFlight 0.1.0 (6) (2026-05-17)

**Superseded by build 7.**

**Scope:** Scanner-toggle **safety / hygiene** release only. Includes `**11efe6c`**: on first launch of a new `CFBundleVersion`, internal scanner toggle resets **off** (fixes build **5** carrying `UserDefaults` across TestFlight update). **No** new product features, service changes, or scanner workflow expansion.


| Item                 | Detail                                                          |
| -------------------- | --------------------------------------------------------------- |
| Marketing version    | **0.1.0** (unchanged)                                           |
| Build                | **6**                                                           |
| Bundle ID            | `io.skyprairie.dockwalk`                                        |
| Compile scanner flag | `liveScannerEnabled` **false**                                  |
| Default for testers  | Scanner **hidden** (no Scanner Lab / scan buttons)              |
| Per-device QA        | More → **Open debug panel** → **Enable scanner on this device** |
| Toggle persistence   | **Within same build** only; **new build → off** on first launch |
| Camera plist         | `NSCameraUsageDescription` present                              |
| Export compliance    | `ITSAppUsesNonExemptEncryption = false`                         |
| Archive              | **ARCHIVE SUCCEEDED**                                           |
| Export/upload        | **EXPORT SUCCEEDED** — Upload succeeded (processing)            |


**Still OFF:** AI/Gemini, OCR cloud, image upload, payments, auth, direct Supabase, task cancel. No backend/service repo edits.

**Why build 6:** Build **5** correctly persisted Debug scanner toggle across TestFlight update; build **6** ensures every new build starts with scanner off until explicitly re-enabled in Debug.

### Build 6 device smoke (2026-05-17, Kyle)


| Area     | Result                                                                                                                                                             |
| -------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Receive  | **Pass**                                                                                                                                                           |
| Putaway  | **Pass** — dev tasks were **in_progress** → **Complete** + **Block** (not Assign/Start); complete qty defaults to **1** (dialog shows task qty e.g. 10 as context) |
| Activity | **Pass**                                                                                                                                                           |
| Sync     | **Pass**                                                                                                                                                           |
| Scanner  | Hidden by default; Debug toggle QA separate                                                                                                                        |


---

## TestFlight 0.1.0 (5) (2026-05-17)

Superseded by build **6**. Phase **1F.1** Debug toggle; toggle could persist across update from prior QA.

---

## Phase 1F.1 — Runtime internal scanner toggle


| Item                 | Detail                                                                                                                      |
| -------------------- | --------------------------------------------------------------------------------------------------------------------------- |
| Compile flag         | `FeatureFlags.liveScannerEnabled` stays `**false`**                                                                         |
| Runtime toggle       | Debug panel → **Enable scanner on this device**                                                                             |
| Persistence          | `DockWalk.internalScannerEnabled` — survives restarts; **resets off** on each new `CFBundleVersion` (TestFlight build bump) |
| Effective gate       | `scannerPreferences.isScannerActive` (= compile **or** internal)                                                            |
| More → Feature flags | Shows **Scanner on device** effective state                                                                                 |
| TestFlight           | **0.1.0 (6)** — toggle resets off on new build; Debug-only enable                                                           |


**Do not** deepen Receive/Putaway scanner workflow until QA passes on device camera.

---

## Phase 1F scanner spike (reference)

**Scope:** Native barcode foundation only. **No** Gemini, OCR cloud, image upload, payments, auth, Supabase client writes, or new Railway routes.


| Item                | Detail                                                                                                                       |
| ------------------- | ---------------------------------------------------------------------------------------------------------------------------- |
| Feature flag        | `FeatureFlags.liveScannerEnabled` — default `**false`**                                                                      |
| When **off**        | No scanner buttons on Today / Receive / Ship / Inventory; no Scanner Lab link                                                |
| When **on**         | **More → Modules → Scanner Lab**; optional **Scan line** on shipment detail; **Scan label** on putaway detail (context only) |
| Framework           | **AVFoundation** metadata (`AVCaptureMetadataOutput`)                                                                        |
| Types               | QR, Code 128, Code 39, EAN-13, EAN-8, UPC-E, PDF417                                                                          |
| Permission          | `NSCameraUsageDescription` in `Info.plist`                                                                                   |
| Simulator           | Manual entry fallback; camera preview hidden when unavailable                                                                |
| Dedup               | ~2s cooldown per identical scan value                                                                                        |
| Receive integration | Scan → match line **SKU** → **Receive 1**                                                                                    |
| Putaway integration | Scan → display scanned code context only (no auto-complete)                                                                  |


**Build:** `xcodegen generate` + `xcodebuild -project DockWalk.xcodeproj -scheme DockWalk -destination 'generic/platform=iOS' build CODE_SIGNING_ALLOWED=NO` → **BUILD SUCCEEDED** (2026-05-17).

**Enable scanner QA:** Debug → **Enable scanner on this device** (preferred). Compile-time: set `liveScannerEnabled = true` + rebuild (only for dev builds).

---

## IA/copy cleanup (post–TestFlight 3 smoke)

**Scope:** Navigation and copy only — **no** API/behavior changes, **no** new TestFlight build.


| Change           | Detail                                                                     |
| ---------------- | -------------------------------------------------------------------------- |
| Putaway entry    | **More → Modules → Putaway tasks** only (removed duplicate under Activity) |
| Activity         | **Audit events** only; footer no longer mentions putaway                   |
| Putaway copy     | Accurate online + offline queue messaging (list + task detail)             |
| Sync empty state | **No queued actions.** when queue is empty                                 |


**Shipped in TestFlight build 4.**

---

## TestFlight 0.1.0 (3) (2026-05-17)

**Scope:** Ship **Phase 1D + 1E** to internal TestFlight. **No** scanner, AI, payments, auth, direct Supabase, or task cancel.


| Included in build | Behavior                                                           |
| ----------------- | ------------------------------------------------------------------ |
| **Phase 1D**      | Putaway assign / start / block / complete (online direct routes)   |
| **Phase 1E**      | Offline `task_action` queue + `POST /api/sync/events` batch replay |
| **Phase 1C**      | Receive offline queue + receiving batch replay (unchanged)         |



| Step                            | Result                                                                                         |
| ------------------------------- | ---------------------------------------------------------------------------------------------- |
| `ITSAppUsesNonExemptEncryption` | `false` in `Info.plist` — confirmed in archived app (`CFBundleVersion` **3**)                  |
| Version                         | Marketing **0.1.0** · build **3**                                                              |
| Bundle ID                       | `io.skyprairie.dockwalk` (unchanged)                                                           |
| Archive                         | **ARCHIVE SUCCEEDED**                                                                          |
| Export + upload                 | **EXPORT SUCCEEDED** · **Upload succeeded** (`ExportOptions.plist` → `upload`)                 |
| Local IPA                       | Upload destination consumed package; no long-lived IPA kept in repo (standard CLI upload flow) |
| Export compliance quiz          | Expect **skipped** (plist `ITSAppUsesNonExemptEncryption` = false)                             |


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


| Check                            | Result                                                                                            |
| -------------------------------- | ------------------------------------------------------------------------------------------------- |
| Git                              | Clean except `dockwalkios.jpeg` — **gitignored** (do not commit; app icon = `AppIcon.appiconset`) |
| Repo build metadata              | `CFBundleVersion` **2**, `ITSAppUsesNonExemptEncryption` **false** in target `Info.plist`         |
| Local `xcodebuild build`         | **BUILD SUCCEEDED** (no new archive/upload)                                                       |
| App Store Connect API from agent | **Not queried** (no ASC issuer in local fastlane env)                                             |


**Kyle — confirm in App Store Connect (TestFlight):**

1. **0.1.0 (2)** finished **Processing** (not still “Processing”)
2. Export-compliance quiz **did not appear** (expected with plist `false`)
3. Build **2** enabled for **DockStockers** (or group uses latest internal build)
4. Optional device smoke on build 2: Railway API test, Receive, Putaway, Activity

Record outcomes here when known; then next iOS feature work is **scanner** (see table below).

---

## API base URLs


| Target                                  | URL                                                                                                  |
| --------------------------------------- | ---------------------------------------------------------------------------------------------------- |
| **Railway production (iOS QA default)** | **[https://dockwalk-api-production.up.railway.app](https://dockwalk-api-production.up.railway.app)** |
| Local (Simulator)                       | `http://localhost:8790`                                                                              |


**More → API connection** — presets, Save & Test, **Reset to Railway QA** / **Reset to local API**.

---

## Supabase split (do not conflate)


| Project       | Ref                    | Use on iOS                                    |
| ------------- | ---------------------- | --------------------------------------------- |
| Service (API) | `egasxwpnutwrqivwmufm` | **Never** — no service-role key on device     |
| iOS client    | `jllqgothyavoqvhugrvf` | App Connect / client SDK only (if used later) |


**Receiving writes:** Railway API only. No direct Supabase inserts from iOS.

---

## iOS-only status


| Area                               | Status                                                                                  |
| ---------------------------------- | --------------------------------------------------------------------------------------- |
| **Receive**                        | Appointments → shipments → lines → **Receive 1** / custom qty                           |
| **Offline queue**                  | Full payload + `idempotency_key`                                                        |
| **Batch replay**                   | `POST /api/sync/events` — `accepted` / `duplicate` dequeue                              |
| **Auto-replay**                    | **More → Sync** (default **OFF**)                                                       |
| **Manual replay**                  | **More → Debug**                                                                        |
| **Putaway**                        | List + detail; **assign / start / block / complete**                                    |
| **Putaway online**                 | Direct `POST /api/tasks/:id/*` (happy path)                                             |
| **Putaway offline**                | Transport failure → `**task_action` queue** → batch replay; **409/400/404** not queued  |
| **Task batch replay**              | `POST /api/sync/events` — `accepted` / `duplicate` dequeue; `**rejected` stays queued** |
| **Audit**                          | **More → Activity → Audit events**                                                      |
| **TestFlight**                     | **0.1.0 (3)** uploaded — **DockStockers** (enable after processing)                     |
| **Scanner / AI / payments / auth** | **OFF**                                                                                 |
| **Task cancel**                    | **OFF** (no API route exposed in app)                                                   |


---

## Latest delivery — Phase 1E offline task-action queue (2026-05-16)

**Scope:** Queue putaway task actions on transport failure; replay via `**task_action`** batch sync. Receiving replay unchanged.


| Path                     | Behavior                                                                              |
| ------------------------ | ------------------------------------------------------------------------------------- |
| Online                   | Direct assign / start / block / complete (`org_id` + `idempotency_key` + `device_id`) |
| Offline / transport      | Enqueue `task_action` with **same** `idempotency_key` as failed direct call           |
| Replay                   | `POST /api/sync/events` — mixed batches with receiving events (up to **50** events)   |
| `accepted` / `duplicate` | Dequeue task action                                                                   |
| `rejected`               | Keep queued; store `lastError` on queue row                                           |
| `409` on direct route    | No queue; refresh task                                                                |
| Auto-replay              | **More → Sync** (default **OFF**) — receiving + task actions when enabled             |


**Files:** `Networking/TaskActionSyncModels.swift`, `SyncBatchModels.swift`, `Persistence/SyncBatchReplayEngine.swift`, `OfflineSyncStore.swift`, `ReceivingEventReplayCoordinator.swift`, `Putaway/PutawayTaskDetailViewModel.swift`, `Settings/SettingsView.swift`, `Debug/DebugPanelView.swift`, `DockWalkTests/DockWalkFoundationTests.swift`

**Build:** `xcodegen generate` + `xcodebuild build CODE_SIGNING_ALLOWED=NO` → **BUILD SUCCEEDED** (no TestFlight / version bump)

---

## Phase 1D putaway task actions (2026-05-16)

**Scope:** Online task writes only. **No** product changes to receive replay, scanner, auth, or Supabase.


| API (Railway)                  | iOS                                                                          |
| ------------------------------ | ---------------------------------------------------------------------------- |
| `POST /api/tasks/:id/assign`   | Assign (pending, blocked)                                                    |
| `POST /api/tasks/:id/start`    | Start (pending, assigned, blocked)                                           |
| `POST /api/tasks/:id/block`    | Block sheet — preset `reason_code` + details                                 |
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


| Priority | Work                                                                                         |
| -------- | -------------------------------------------------------------------------------------------- |
| P1       | Device smoke **TestFlight 0.1.0 (7)** — verify WMS shell on device (see checklist above)     |
| P2       | Scanner device QA (Debug toggle); then deepen Receive/Putaway scan workflow                  |
| P3       | Inventory: wire live API routes if available (`GET /api/inventory/items`, `/locations`)      |
| P4       | Ship: wire live API routes when available (outbound orders, pick/stage writes)               |
| P5       | Auth / mobile session                                                                        |
| P6       | Task cancel when API adds route                                                              |


---

## Cursor

Backend: **ARCHITECT_RECAP** + **api-foundation** + **sync-contract**. iOS: **this file**. `**DOCKWALK.md`** umbrella snapshot is manual.