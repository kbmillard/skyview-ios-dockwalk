# DockWalk iOS — service handoff

**Last updated:** 2026-05-17 (iOS agent; lines path corrected per service recap)

**Canonical system state (API, Supabase service DB, workers, phases):**  
[ARCHITECT_RECAP.md](https://github.com/kbmillard/skyview-dockwalk/blob/main/docs/architecture/ARCHITECT_RECAP.md)

**API contract (paths, query params, stub vs live):**  
[api-foundation.md](https://github.com/kbmillard/skyview-dockwalk/blob/main/docs/contracts/api-foundation.md)

**Sibling pairing (two-repo Cursor workflow):**  
[SIBLING_IOS.md](https://github.com/kbmillard/skyview-dockwalk/blob/main/docs/architecture/SIBLING_IOS.md)

**Umbrella index (“dad” `skyview` meta repo):**  
[DOCKWALK.md](https://github.com/kbmillard/SkyView/blob/main/docs/products/DOCKWALK.md) — links both siblings; open `~/Desktop/skyview` with product folders in one workspace.

---

## Repo split

| | This repo | [skyview-dockwalk](https://github.com/kbmillard/skyview-dockwalk) |
|--|-----------|-------------------------------------------------------------------|
| **Owns** | SwiftUI, offline queue, device config | Express API, migrations, portal worker, Railway |
| **Supabase** | `jllqgothyavoqvhugrvf` (client / Connect key) | `egasxwpnutwrqivwmufm` (service role on server only) |
| **Do not** | Run WMS migrations or store service_role here | Ship iOS UI |

---

## Local dev (iOS + API)

1. **Service repo:** `cd skyview-dockwalk/apps/api/dockwalk-api && npm run dev` → `:8790`, `supabase: configured`.
2. **This app:** `AppEnvironment.apiBaseURL` defaults to `http://localhost:8790`.
3. **Physical device:** use your Mac’s LAN IP, e.g. `http://192.168.x.x:8790` (Settings / Debug panel).
4. **Smoke data:** dev org `00000000-0000-4000-8000-000000000001` — seed + sample appointments on **egas** (see service recap).

---

## iOS-only status (edit this section)

| Area | Status |
|------|--------|
| **Receive — appointments** | `AppointmentsViewModel` → `GET /api/appointments?org_id=` |
| **Receive — inbound** | `ReceivingViewModel` → `GET /api/inbound/shipments` (filter by appointment) |
| **Offline queue** | `OfflineSyncStore` + `dockwalk_sync_queue.json` persistence |
| **Scanner** | Placeholder (`liveScannerEnabled` off) |
| **AI inspection** | Stub UI; `aiInspectionEnabled` off |
| **Payments** | Stub; `paymentsEnabled` off |
| **Auth** | None yet — dev org UUID in `AppEnvironment` |

---

## First delivery summary (iOS agent)

**Repo:** [skyview-ios-dockwalk](https://github.com/kbmillard/skyview-ios-dockwalk) · **Commits:** `1cce9c8` (WMS foundation) → `2aedab6` (Phase 1A API wiring)

### What shipped

1. **Foundation** — SwiftUI shell with tabs Today / Receive / Ship / Inventory / More; design system; stub ViewModels for ship/inventory; feature flags (AI/payments/scanner off, offline sync on).
2. **Phase 1A networking** — Live reads against local DockWalk API:
   - `AppointmentsViewModel` → `GET /api/appointments?org_id={AppEnvironment.orgId}`
   - `ReceivingViewModel` → `GET /api/inbound/shipments`, client-filtered by `appointment_id`
   - DTOs in `Networking/APIModels.swift`, mapping in `Inbound/InboundAPIMapping.swift`
3. **UX states** — `LoadPhase` + `LoadStateView` (loading / empty with API stub message / error + retry) on Receive list and Receiving shipments.
4. **Offline queue** — `SyncQueuePersistence` writes `Application Support/DockWalk/dockwalk_sync_queue.json`; survives app restart.
5. **Xcode** — `DockWalk.xcodeproj` via `apps/ios/dockwalk/project.yml` (XcodeGen).

### Dev defaults (aligned with service seed)

| Key | Value |
|-----|--------|
| `apiBaseURL` | `http://localhost:8790` |
| `orgId` | `00000000-0000-4000-8000-000000000001` |
| `facilityId` | `00000000-0000-4000-8000-000000000010` |

### Validation (last run)

```bash
cd apps/ios/dockwalk
xcodebuild -project DockWalk.xcodeproj -scheme DockWalk \
  -destination 'generic/platform=iOS' build CODE_SIGNING_ALLOWED=NO
# BUILD SUCCEEDED

xcodebuild -project DockWalk.xcodeproj -scheme DockWalk \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' test CODE_SIGNING_ALLOWED=NO
# 7 tests passed
```

### Operator notes

- **Empty Receive list** with API up usually means `mode: "stub"` on the server (no Supabase) or no rows for the dev org — not an iOS bug. With **egas** seeded, curl the same `org_id` and you should see two appointments; pull-to-refresh on Receive.
- **Receiving shipments** section shows inbound shipment headers for the appointment; **lines API exists** (`GET /api/inbound/shipments/:id/lines?org_id=`) — iOS does not call it yet (still maps shipments into the list).
- **Simulator → Mac API:** use LAN IP in Settings/Debug if `localhost` fails on device.

### Intentionally not started

Live AVFoundation scanner, Gemini/cloud inspection, PaymentManager / PSP SDKs, Supabase direct reads from iOS (HTTP-only for Phase 1A lists), production Railway base URL, auth headers.

### Suggested next iOS PR

| Priority | Work |
|----------|------|
| P0 | Settings field for API base URL + org id (persisted, not hardcoded) |
| P1 | Wire inbound **lines** UI → `GET /api/inbound/shipments/:id/lines?org_id=` (route live on service) |
| P1 | Replay offline queue to API when write routes exist |
| P2 | Auth header / Supabase session when service defines mobile auth |
| P3 | Live scanner behind `liveScannerEnabled` |

---

## When to PR which repo

| Change | Repo |
|--------|------|
| New API route, schema, recap, contract | **skyview-dockwalk** first |
| Swift UI, ViewModels, flags, offline behavior | **skyview-ios-dockwalk** |
| API assumption changes | Link both PRs in descriptions |

---

## Cursor

Add **both** repo roots to one workspace: `skyview-dockwalk` + `skyview-ios-dockwalk`. iOS agents: read service recap + contract before changing networking code.
