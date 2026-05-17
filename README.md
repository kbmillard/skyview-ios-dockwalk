# DockWalk iOS

DockWalk is an **iOS-first Warehouse Management System** for dock workers, receivers, pickers, loaders, and supervisors at small-to-mid warehouses and 3PLs.

This repository is the **DockWalk iOS client only**.

| Repo | Purpose |
|------|---------|
| **This repo** (`skyview-ios-dockwalk`) | SwiftUI app, scanner-first WMS screens, offline/sync scaffolding, design system |
| **Sibling** [`../skyview-dockwalk`](../skyview-dockwalk) | DockWalk API, Supabase migrations, Railway deploy |

**DockWalk is not SiteWalk.** Do not import SiteWalk code or schemes here.

## WMS core first

Foundation build focuses on:

1. **Today** — shift overview, sync status, quick actions  
2. **Receive** — appointments and inbound receiving  
3. **Ship** — outbound staging and load scan placeholder  
4. **Inventory** — lookup and cycle count placeholder  
5. **More** — settings, feature flags, debug  

AI inspection and POS/payments are **intentionally stubbed** (feature flags off by default).

## Open and build

```bash
cd apps/ios/dockwalk
open DockWalk.xcodeproj
```

In Xcode: select the **DockWalk** scheme → run on a simulator or device.

Command-line build (no signing):

```bash
xcodebuild -project apps/ios/dockwalk/DockWalk.xcodeproj \
  -scheme DockWalk \
  -destination 'generic/platform=iOS' \
  build CODE_SIGNING_ALLOWED=NO
```

See [`docs/MANUAL_XCODE_SETUP.md`](docs/MANUAL_XCODE_SETUP.md) if you need to recreate the Xcode project.

## Docs

- [`docs/IOS_FOUNDATION.md`](docs/IOS_FOUNDATION.md) — folder layout and stub state  
- [`docs/APP_STORE_MVP_NOTES.md`](docs/APP_STORE_MVP_NOTES.md) — App Store positioning  
- [`docs/MANUAL_XCODE_SETUP.md`](docs/MANUAL_XCODE_SETUP.md) — manual Xcode steps  

## Local API placeholder

Default API base URL: `http://localhost:8790` (DockWalk API in `skyview-dockwalk`). ViewModels use **stub data** until Phase 1A wires live responses.
