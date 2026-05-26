# DockWalk Facility API Contract (iOS ↔ Backend)

Version 1.0 · Multi-tenant · Search-only catalog

---

## Principles

1. **Never** return the full facility SKU catalog on login.
2. **FIFO offline replay:** Putaway/movement events for a line must not be applied until that line's finalize (or receive commit) is acknowledged.
3. **Ad-hoc receive:** Unknown UPCs may finalize with `sku: null` and/or `is_unregistered_upc: true`.

---

## 1. `GET /api/facilities/{facilityId}/config`

```json
{
  "facility_id": "fac_abc123",
  "facility_name": "SkyPrairie Demo DC",
  "receive": {
    "default_staging_location_code": "RECV-STAGE",
    "staging_display_name": "Receive staging"
  },
  "stages": [
    { "key": "scheduled", "label": "Scheduled" },
    { "key": "receiving", "label": "Receiving" }
  ],
  "updated_at": "2026-05-24T12:00:00Z"
}
```

---

## 2. `GET /api/facilities/{facilityId}/locations`

Paginate when `total > limit` (default limit 500).

```json
{
  "items": [
    { "code": "A-12-03", "zone": "A", "type": "storage" },
    { "code": "RECV-STAGE", "zone": "INBOUND", "type": "staging" }
  ],
  "pagination": { "offset": 0, "limit": 500, "total": 1240 },
  "updated_at": "2026-05-24T12:00:00Z"
}
```

### 2.1 `GET /api/facilities/{facilityId}/locations/{code}`

Validate a single bin when local cache may be incomplete (worker scanned before pagination finished).

**200:**
```json
{ "code": "Z-99-01", "zone": "Z", "type": "storage", "valid": true }
```

**404:** `{ "error": { "code": "invalid_location", "message": "..." } }`

---

## 3. `GET /api/facilities/{facilityId}/catalog/search`

Query: `q` (min 2 chars), `limit` (default 25, max 50).

```json
{
  "query": "012345",
  "items": [
    {
      "sku": "SKU-100200",
      "upc": "012345678901",
      "item_name": "Widget A",
      "default_uom": "EA",
      "cases_per_case": 12
    }
  ],
  "pagination": { "offset": 0, "limit": 25, "total": 3 }
}
```

---

## 4. `GET /api/facilities/{facilityId}/catalog/lookup`

Query: `upc` or `sku` (one required).

**200:** `{ "item": { "sku": "...", "upc": "...", "item_name": "..." } }`  
**404:** Worker may enter manual receive fields; see §5.

---

## 5. `POST /api/inbound/loads/{loadId}/finalize`

```json
{
  "idempotency_key": "550e8400-e29b-41d4-a716-446655440000",
  "facility_id": "fac_abc123",
  "lines": [
    {
      "client_line_id": "draft-uuid",
      "upc": "012345678901",
      "sku": "SKU-100200",
      "is_unregistered_upc": false,
      "cases": 2,
      "eaches_per_case": 12,
      "location_code": "RECV-STAGE",
      "status": "available"
    },
    {
      "client_line_id": "draft-uuid-2",
      "upc": "0999888777666",
      "sku": null,
      "is_unregistered_upc": true,
      "cases": 1,
      "eaches_per_case": 6,
      "location_code": "RECV-STAGE",
      "status": "available"
    }
  ]
}
```

**Rules:**
- `sku` may be `null` when `is_unregistered_upc` is true.
- Server must not reject unknown SKU if UPC + quantity + location are present.

**200:** `{ "load_id": "T-4401", "status": "completed", "committed_line_count": 2 }`

---

## 6. `POST /api/inventory/movements`

```json
{
  "idempotency_key": "550e8400-e29b-41d4-a716-446655440001",
  "facility_id": "fac_abc123",
  "movement_type": "putaway",
  "upc": "012345678901",
  "from_location_code": "RECV-STAGE",
  "to_location_code": "A-12-03",
  "quantity": 24,
  "uom": "EA",
  "inbound_load_id": "T-4401",
  "client_line_id": "draft-uuid"
}
```

**Ordering:** Server rejects if line not finalized. iOS queues movement **after** finalize in `OfflineSyncStore` (FIFO per `inbound_load_id` + `client_line_id`).

---

## 7. Errors

```json
{
  "error": {
    "code": "invalid_location",
    "message": "Location B-99-99 is not valid for this facility"
  }
}
```

Common codes: `invalid_location`, `line_not_finalized`, `catalog_not_found`, `validation_error`.
