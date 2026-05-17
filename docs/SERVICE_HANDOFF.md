# DockWalk iOS — service handoff

**Last updated:** 2026-05-17 (iOS agent — inbound lines + receiving events + Railway preset)

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

## API base URLs

| Target | URL | How to use in app |
|--------|-----|-------------------|
| **Local (Simulator)** | `http://localhost:8790` | Dev default; API via `npm run dev` in service repo |
| **Local (device)** | `http://<Mac-LAN-IP>:8790` | Manual entry in **More → API connection** |
| **Railway production** | `https://dockwalk-api-production.up.railway.app` | **More → API connection → Use Railway production** → Save & Test |

Dev org / facility (seed on **egas**): `00000000-0000-4000-8000-000000000001` / `00000000-0000-4000-8000-000000000010`

**Device QA (2026-05-17):** Production URL + health test (`supabase: configured`, `API env: production`) verified on physical device.

---

## iOS-only status (edit this section)

| Area | Status |
|------|--------|
| **API connection settings** | Persisted URL + org + facility; presets for **Railway production** and **local simulator** |
| **Health test** | `GET /health` — works for localhost, LAN, or Railway |
| **Receive — appointments** | `GET /api/appointments?org_id=` |
| **Receive — inbound shipments** | `GET /api/inbound/shipments?org_id=&appointment_id=` |
| **Receive — inbound lines** | `GET /api/inbound/shipments/:id/lines?org_id=` |
| **Receive — record event** | `POST /api/inbound/receiving-events` (`manual_receive`, `committed`, idempotency key) |
| **Offline queue** | Receiving events store full `CreateReceivingEventRequest` payload |
| **Offline replay** | Debug → **Replay receiving events** only (not auto on reconnect) |
| **Scanner** | Placeholder (`liveScannerEnabled` off) |
| **AI inspection** | Stub UI; `aiInspectionEnabled` off |
| **Payments** | Stub; `paymentsEnabled` off |
| **Auth** | None — org/facility from persisted config |

---

## Latest delivery (inbound lines + receiving events + Railway preset)

**What changed**

- **Shipment detail:** Receive → appointment → shipment → lines (`GET .../lines?org_id=`)
- **Manual receive:** `POST /api/inbound/receiving-events` with contract payload; idempotency key per submit; duplicate-safe success UI
- **Fill remaining qty** / per-line **Receive now** quantity
- **Offline:** transport failure queues receiving event; **Queued offline** banner
- **Debug:** replay queued receiving events only
- **API connection:** **Use Railway production** / **Use local simulator API** presets (optional; not forced)
- **Inbound shipments** query includes `org_id` + `appointment_id`

**Files (main)**

- `Inbound/ShipmentDetailView.swift`, `Inbound/ShipmentDetailViewModel.swift`
- `Inbound/ReceivingView.swift`, `Inbound/ReceivingViewModel.swift`
- `Inbound/InboundModels.swift`, `Inbound/InboundAPIMapping.swift`
- `Networking/APIEndpoint.swift`, `Networking/ReceivingEventModels.swift`
- `Settings/APIConnectionSettingsView.swift`, `Core/DeviceConfiguration.swift`
- `Persistence/OfflineSyncStore.swift`, `Persistence/SyncQueuePersistence.swift`
- `Debug/DebugPanelView.swift`
- `DockWalkTests/DockWalkFoundationTests.swift`

**Still off:** live scanner, Gemini/cloud inspection, payments/PSP, auth headers, direct Supabase from iOS.

**Validation (2026-05-17)**

```bash
cd apps/ios/dockwalk
xcodebuild -project DockWalk.xcodeproj -scheme DockWalk \
  -destination 'generic/platform=iOS' build CODE_SIGNING_ALLOWED=NO
# BUILD SUCCEEDED

xcodebuild -project DockWalk.xcodeproj -scheme DockWalk \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' test CODE_SIGNING_ALLOWED=NO
# TEST SUCCEEDED — 15 tests
```

**Limitations**

- Queued receiving events are **not** auto-replayed when API returns — use **More → Debug → Replay receiving events**.
- Other queue kinds (`inbound.start`, `exception`) have no structured replay.
- `/health` does not expose list `mode: live|stub`.

---

## Prior delivery (persisted API config)

`DeviceConfigurationStore`, **More → API connection**, health test, `AppEnvironment` — see git `3f6d866`.

---

## Suggested next iOS PR

| Priority | Work |
|----------|------|
| P1 | Auto-replay receiving events on reachability (narrow, behind flag) |
| P2 | Auth / mobile session when service defines it |
| P3 | Live scanner; audit list read (`GET /api/audit/events`) |

---

## When to PR which repo

| Change | Repo |
|--------|------|
| API route, schema, recap, contract | **skyview-dockwalk** |
| Swift UI, ViewModels, flags, offline, this handoff | **skyview-ios-dockwalk** |

---

## Cursor

Workspace: `skyview-dockwalk` + `skyview-ios-dockwalk`. Backend truth: **ARCHITECT_RECAP** (overrides umbrella index if stale).
