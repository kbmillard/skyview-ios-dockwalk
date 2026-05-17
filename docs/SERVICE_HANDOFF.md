# DockWalk iOS — service handoff

**Last updated:** 2026-05-17 (iOS agent — persisted API connection settings)

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
2. **This app:** **More → API connection** (or Debug → API connection & health test). Defaults match dev seed; values persist in UserDefaults.
3. **Simulator:** `http://localhost:8790`
4. **Physical device:** Mac LAN IP, e.g. `http://192.168.x.x:8790` — save in API connection, then **Test API connection** (`GET /health`).
5. **Smoke data:** dev org `00000000-0000-4000-8000-000000000001` — seed on **egas** (see service recap).

---

## iOS-only status (edit this section)

| Area | Status |
|------|--------|
| **API connection settings** | Persisted URL + org + facility (`DeviceConfigurationStore` / UserDefaults); **More → API connection** |
| **Health test** | `GET /health` — shows `status`, `service`, `supabase` (`configured` \| `stub`) |
| **Receive — appointments** | `AppointmentsViewModel` → `GET /api/appointments?org_id=` (reads live `AppEnvironment`) |
| **Receive — inbound** | `ReceivingViewModel` → `GET /api/inbound/shipments` (filter by appointment; reloads on config change) |
| **Offline queue** | `OfflineSyncStore` + `dockwalk_sync_queue.json` persistence |
| **Scanner** | Placeholder (`liveScannerEnabled` off) |
| **AI inspection** | Stub UI; `aiInspectionEnabled` off |
| **Payments** | Stub; `paymentsEnabled` off |
| **Auth** | None yet — org/facility from persisted config |

---

## Latest delivery (persisted API config)

**What changed**

- `DeviceConfiguration` + `DeviceConfigurationStore` (UserDefaults) with dev defaults fallback
- `AppEnvironment` loads/saves config, `configRevision` bumps on apply/reset, `makeAPIClient()` for ViewModels
- **APIConnectionSettingsView** — edit URL/org/facility, Save & apply, Reset to dev defaults, Test API connection
- ViewModels use `AppEnvironment` per refresh (no hardcoded localhost in VMs)
- Receive list reloads when `configRevision` changes after save

**Files (main)**

- `Core/DeviceConfiguration.swift`, `Persistence/DeviceConfigurationStore.swift`
- `Core/AppEnvironment.swift`
- `Settings/APIConnectionSettingsView.swift`, `Settings/SettingsView.swift`, `Debug/DebugPanelView.swift`
- `Inbound/AppointmentsViewModel.swift`, `Inbound/ReceivingViewModel.swift`, `Inbound/AppointmentsView.swift`
- `Networking/APIClient.swift` (`fetchHealth`, expanded `HealthResponse`)

**Still off:** live scanner, Gemini, payments, auth headers, direct Supabase from iOS, Railway prod URL field (manual base URL only).

**Validation (2026-05-17)**

```bash
cd apps/ios/dockwalk
xcodebuild -project DockWalk.xcodeproj -scheme DockWalk \
  -destination 'generic/platform=iOS' build CODE_SIGNING_ALLOWED=NO
# BUILD SUCCEEDED

xcodebuild -project DockWalk.xcodeproj -scheme DockWalk \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' test CODE_SIGNING_ALLOWED=NO
# TEST SUCCEEDED — 9 tests
```

**Limitation:** `/health` does not report list `mode: live|stub`; only `supabase: configured|stub`. Use Receive pull-to-refresh or appointments response for list mode.

---

## First delivery summary (iOS agent)

**Repo:** [skyview-ios-dockwalk](https://github.com/kbmillard/skyview-ios-dockwalk) · **Commits:** `1cce9c8` (foundation) → `2aedab6` (Phase 1A API wiring) → `ae0300f` (handoff fix)

See git history for full detail. Foundation + Phase 1A lists documented in earlier commits.

### Suggested next iOS PR

| Priority | Work |
|----------|------|
| P1 | Wire inbound **lines** UI → `GET /api/inbound/shipments/:id/lines?org_id=` |
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
