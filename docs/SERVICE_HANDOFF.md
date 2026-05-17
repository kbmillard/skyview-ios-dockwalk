# DockWalk iOS — service handoff

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

## When to PR which repo

| Change | Repo |
|--------|------|
| New API route, schema, recap, contract | **skyview-dockwalk** first |
| Swift UI, ViewModels, flags, offline behavior | **skyview-ios-dockwalk** |
| API assumption changes | Link both PRs in descriptions |

---

## Cursor

Add **both** repo roots to one workspace: `skyview-dockwalk` + `skyview-ios-dockwalk`. iOS agents: read service recap + contract before changing networking code.
