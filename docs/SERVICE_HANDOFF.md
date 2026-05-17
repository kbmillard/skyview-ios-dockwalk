# DockWalk iOS — service handoff

**Last updated:** 2026-05-17 (iOS agent — read-only audit / activity list)

**Canonical backend:** [ARCHITECT_RECAP.md](https://github.com/kbmillard/skyview-dockwalk/blob/main/docs/architecture/ARCHITECT_RECAP.md)  
**API contract:** [api-foundation.md](https://github.com/kbmillard/skyview-dockwalk/blob/main/docs/contracts/api-foundation.md)  
**Umbrella:** [DOCKWALK.md](https://github.com/kbmillard/SkyView/blob/main/docs/products/DOCKWALK.md)

---

## API base URLs

| Target | URL |
|--------|-----|
| **Railway production (iOS QA default)** | **https://dockwalk-api-production.up.railway.app** |
| Local (Simulator) | `http://localhost:8790` |

**More → API connection** — presets, Save & Test.

---

## iOS-only status

| Area | Status |
|------|--------|
| **Receive workflow** | Appointments → shipments → lines → **Receive 1** / custom quantities |
| **Receiving POST** | `POST /api/inbound/receiving-events` — `source: device`, `event_type: receive_scan` |
| **Offline queue + replay** | Receiving events only; manual Debug + runtime auto-replay toggle (default OFF) |
| **Activity / audit (read-only)** | **More → Activity → Audit events** — `GET /api/audit/events?org_id=&limit=&offset=` |
| **Auth / mobile session** | **Not implemented** — waiting on service contract |
| **Scanner / AI / payments / direct Supabase** | **OFF** |

---

## Latest delivery (read-only audit / activity list)

**What changed**

- **`GET /api/audit/events`** wired with org/limit/offset from `AppEnvironment`
- **More → Activity → Audit events** — loading, empty, error+retry, pull-to-refresh, **Load more**
- Row shows action, entity type, timestamp, payload summary (when API returns payload fields)
- Tap row → detail sheet (entity ID, source, device, idempotency key, line count, etc. — only fields present in API)
- After successful receive on shipment detail → **View activity** navigates to Activity (non-blocking)
- **Read-only** — no writes, no auth headers, no Supabase on device

**Files (main)**

- `Networking/AuditEventModels.swift`, `Networking/APIEndpoint.swift`, `Networking/APIClient.swift`
- `Activity/ActivityView.swift`, `Activity/ActivityViewModel.swift`
- `Settings/SettingsView.swift`, `Inbound/ShipmentDetailView.swift`
- `DockWalkTests/DockWalkFoundationTests.swift`

**Still off:** scanner, Gemini, payments, auth, direct Supabase.

**Validation (2026-05-17)**

```bash
cd apps/ios/dockwalk
xcodebuild -project DockWalk.xcodeproj -scheme DockWalk -destination 'generic/platform=iOS' build CODE_SIGNING_ALLOWED=NO
# BUILD SUCCEEDED

xcodebuild -project DockWalk.xcodeproj -scheme DockWalk -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' test CODE_SIGNING_ALLOWED=NO
# TEST SUCCEEDED — 31 tests
```

**Limitations**

- Audit list shows fields returned by API (`entity_type`, `action`, `payload` keys present in service writes). No invented columns.
- Stub API mode returns empty audit list with message.
- No filtering by entity type in UI yet (full org trail only).

---

## Prior delivery (Phase 1B + replay)

- Railway QA defaults, inbound lines, device receiving writes, offline queue, auto-replay UserDefaults toggle — see git `71d0efc` / Phase 1B section in history.

---

## Suggested next iOS PR

| Priority | Work |
|----------|------|
| P1 | Auth / mobile session when service defines it |
| P2 | Live scanner (replace manual Receive 1) |
| P3 | Filter Activity by `receiving_event` entity type |

---

## Cursor

Backend: **ARCHITECT_RECAP** + **api-foundation**. iOS: **this file**.
