# Copy to `.cursor/rules/ios-execution-engine.mdc` on execute

```yaml
---
description: DockWalk iOS is a multi-tenant execution engine — API/UI/local firewall
globs: apps/ios/dockwalk/**
alwaysApply: true
---
```

# DockWalk iOS — Execution engine only

Multi-tenant SaaS for 1,000+ facilities. **Never** hardcode facility catalogs, location lists, or stage names in production paths.

## API boundary

- Facility config, valid locations, and catalog metadata come **only** from API responses.
- Catalog: `search?q=` and `lookup?upc=` only — **never** download the full catalog on login.
- If API is unavailable: empty states + `OfflineSyncStore` queue — **no** `FoundationOperationalData` fallback in Release.

## UI boundary

Dock worker flows only: receive, putaway, pick, ship, inventory lookup. **No** BOL, invoice, payment, or reporting UI.

## Local boundary

- Session stores for active scans; `OfflineSyncStore` for FIFO replay.
- **Putaway/movement must not replay before finalize** for the same `inbound_load_id` + `client_line_id`.

## Edge cases

- **Location sync trap:** If locations still paginating, show "Syncing locations…" or `GET .../locations/{code}` before invalid error.
- **Ad-hoc receive:** Finalize may send `sku: null`, `is_unregistered_upc: true`.
