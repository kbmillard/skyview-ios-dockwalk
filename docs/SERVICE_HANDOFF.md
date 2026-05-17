# DockWalk iOS — service handoff

**Last updated:** 2026-05-17 (iOS Phase 1B — inbound lines + device receiving writes)

**Canonical backend:** [ARCHITECT_RECAP.md](https://github.com/kbmillard/skyview-dockwalk/blob/main/docs/architecture/ARCHITECT_RECAP.md)  
**API contract:** [api-foundation.md](https://github.com/kbmillard/skyview-dockwalk/blob/main/docs/contracts/api-foundation.md)  
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

**Receiving writes:** `POST /api/inbound/receiving-events` on Railway → API writes to **egas**. iOS does **not** insert receiving rows into Supabase directly.

---

## iOS-only status

| Area | Status |
|------|--------|
| **Receive workflow** | Appointments → shipments → **shipment detail + lines** → **Receive 1** (manual scan commit) |
| **Inbound lines** | `GET /api/inbound/shipments/:id/lines?org_id=` — Phase 1B contract (`quantity_*`, `inbound_shipment_id`) |
| **Receiving POST** | `POST /api/inbound/receiving-events` — `source: device`, `event_type: receive_scan`, idempotency |
| **Idempotency** | New UUID per user tap; **same key** when offline queue replays |
| **Idempotent replay** | HTTP 200 + `idempotent: true` + `item` → treated as success |
| **Offline queue** | Receiving events persisted with payload + `idempotency_key` |
| **Manual replay** | **More → Debug → Replay receiving events** |
| **Auto-replay** | **More → Sync → Auto-replay receiving events** (default OFF) |
| **Scanner / AI / payments / auth** | **OFF** |

---

## Phase 1B delivery (2026-05-17)

**Flows**

1. **Receive** tab → appointment → inbound shipment → **shipment detail**
2. Lines load from API; each line shows SKU, expected/received/damaged, status
3. **Receive 1** posts one line (`quantity_received: 1`) without live scanner
4. Optional **Record custom quantities** for multi-line commit

**Defaults**

- Fresh install: Railway QA URL + dev org `00000000-0000-4000-8000-000000000001` + facility `…0010`
- Dev sample shipment on production: `00000000-0000-4000-8000-000000000201` (ASN-DEV-001)

**Key files**

- `Networking/ReceivingEventModels.swift` — `InboundLinesResponse`, `ReceivingEventResponse`, request types
- `Inbound/InboundLineRowView.swift`, `ShipmentDetailView*.swift`
- `Core/DeviceConfiguration.swift` — `railwayQADefaults` / `localDevDefaults`

**Validation**

```bash
cd apps/ios/dockwalk
xcodebuild -project DockWalk.xcodeproj -scheme DockWalk -destination 'generic/platform=iOS' build CODE_SIGNING_ALLOWED=NO
# BUILD SUCCEEDED

xcodebuild -project DockWalk.xcodeproj -scheme DockWalk -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' test CODE_SIGNING_ALLOWED=NO
# TEST SUCCEEDED — 28 tests
```

---

## Prior delivery

- Runtime auto-replay toggle (Sync preferences)
- Auto-replay engine + manual Debug replay
- Phase 1A: appointments/shipments lists, API settings, offline queue scaffold

---

## Suggested next iOS PR

| Priority | Work |
|----------|------|
| P1 | Auth / mobile session when service defines it |
| P2 | Live scanner (replace manual Receive 1) |
| P3 | Audit list read in app |

---

## Cursor

Backend: **ARCHITECT_RECAP** + **api-foundation**. iOS: **this file**.
