# DockWalk iOS — Architecture Boundary

The iOS app is a **local execution engine** for dock workers. It is not the system of record.

## Server (brains)

- Master SKU catalog, facility layouts, stage naming
- Bills of lading, invoices, payments, reporting
- All facility-specific configuration

## iOS (muscle)

- `InboundSessionStore` / `PutawaySessionStore` — scan scratchpads
- `OfflineSyncStore` — FIFO replay of API payloads
- Scanner, haptics, universal movement FSM
- Receive → Putaway → Allocate → Pick (physics only)

## Three rules

1. **API boundary** — Locations, staging names, catalog metadata from API only (search/lookup, never full catalog on login).
2. **UI boundary** — No back-office screens on iOS.
3. **Local boundary** — Queue opaque payloads; enforce offline FIFO so putaway never replays before finalize for the same line.

## Edge cases (required)

| Case | Behavior |
|------|----------|
| Offline race | Putaway queued behind finalize for same `loadId` + `client_line_id` |
| Unknown UPC | Finalize with `sku: null` / `is_unregistered_upc: true` |
| Location pagination | Block or server-validate bin while locations syncing |

See [facility-config-contract.md](../../../docs/api/facility-config-contract.md) and [DockWalk_QA_Flow_Checklist.md](DockWalk_QA_Flow_Checklist.md).
