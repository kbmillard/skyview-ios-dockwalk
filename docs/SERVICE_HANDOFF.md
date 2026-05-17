# DockWalk iOS — service handoff

**Last updated:** 2026-05-17 (iOS agent — Phase 1C backend on Railway noted; iOS putaway/sync not started)

**Canonical backend:** [ARCHITECT_RECAP.md](https://github.com/kbmillard/skyview-dockwalk/blob/main/docs/architecture/ARCHITECT_RECAP.md)  
**API contract:** [api-foundation.md](https://github.com/kbmillard/skyview-dockwalk/blob/main/docs/contracts/api-foundation.md) · [sync-contract.md](https://github.com/kbmillard/skyview-dockwalk/blob/main/docs/contracts/sync-contract.md)  
**Umbrella:** [DOCKWALK.md](https://github.com/kbmillard/SkyView/blob/main/docs/products/DOCKWALK.md)

---

## API base URLs (QA)

| Target | URL |
|--------|-----|
| **Railway production (iOS default)** | **https://dockwalk-api-production.up.railway.app** |
| Local (Simulator) | `http://localhost:8790` |

**No local API terminal required for QA** — point **More → API connection** at Railway, Save & Test.

Dev org: `00000000-0000-4000-8000-000000000001` · facility: `00000000-0000-4000-8000-000000000010`

---

## Backend Phase 1C on Railway (service — live)

**Service commit:** `017eb54` on `skyview-dockwalk` `main`  
**Verified:** `railway up --service dockwalk-api`, `scripts/railway-smoke.sh` all passed

| Check | Result |
|-------|--------|
| `POST /api/sync/events` | **200** (was 501 pre-deploy) |
| Sync batch idempotent replay | OK |
| `GET /api/tasks?task_type=putaway&org_id=…` | **2** dev putaway tasks (smoke) |

**iOS does not implement these yet** — next PR targets below.

---

## iOS-only status

| Area | Status |
|------|--------|
| **Receive workflow** | Appointments → shipments → lines → **Receive 1** / custom quantities |
| **Receiving POST** | `POST /api/inbound/receiving-events` — `source: device`, `event_type: receive_scan` |
| **Offline queue + replay** | Per-event queue; auto-replay toggle in **More → Sync** (default OFF); Debug manual replay |
| **Activity / audit** | **More → Activity → Audit events** (read-only) |
| **Putaway tasks** | **Not wired** — API ready: `GET /api/tasks?task_type=putaway` |
| **Batch sync replay** | **Not wired** — API ready: `POST /api/sync/events` (optional upgrade from per-event replay) |
| **Auth / mobile session** | **Not implemented** — waiting on service |
| **Scanner / AI / payments / direct Supabase** | **OFF** |

---

## Latest iOS delivery (audit / activity — `8e9a5c0`)

Read-only **`GET /api/audit/events`** · **More → Activity** · **View activity** after receive · **31 tests** at that commit.

See git history for files and validation output.

---

## Suggested next iOS PR (Phase 1C consumer)

| Priority | Work | Contract |
|----------|------|----------|
| **P1** | **Putaway task list** (read-only) | `GET /api/tasks?org_id=&task_type=putaway` — show SKU, qty, from/to location, status |
| **P2** | **Optional:** replay offline queue via `POST /api/sync/events` | [sync-contract.md](https://github.com/kbmillard/skyview-dockwalk/blob/main/docs/contracts/sync-contract.md) — preserve `idempotency_key`; map `duplicate` → success |
| P3 | Auth when service defines mobile session |
| P4 | Live scanner |

**Do not** implement task assign/complete writes (still stub on service).

---

## Cursor

- **Backend truth:** ARCHITECT_RECAP + api-foundation (not duplicated here).  
- **iOS truth:** this file.  
- **`DOCKWALK.md` (umbrella):** does **not** auto-sync from this file — bump phase snapshot manually when iOS catches up.
