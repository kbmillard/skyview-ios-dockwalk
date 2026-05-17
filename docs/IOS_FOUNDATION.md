# DockWalk iOS — foundation

## Folder structure

```
apps/ios/dockwalk/
  DockWalk/
    App/           — @main, tab shell, Today
    DesignSystem/  — theme, buttons, chips, cards
    Core/          — environment, feature flags, shared types
    Networking/    — APIClient, endpoints (stub-friendly)
    Persistence/   — offline queue placeholder, sync status
    Scanner/       — placeholder scanner UI (no AVFoundation)
    Inbound/       — appointments, receiving
    Outbound/      — shipping home
    Inventory/     — lookup, cycle count placeholder
    Tasks/         — placeholder
    Exceptions/    — placeholder
    Inspections/   — camera/AI stub only
    Settings/      — More tab
    Debug/         — internal debug panel
    Resources/     — Assets, Info.plist
  DockWalkTests/
  DockWalk.xcodeproj
  project.yml          # XcodeGen spec — run `xcodegen generate` after file changes
```

## Module responsibilities

| Area | Responsibility |
|------|----------------|
| **App** | Navigation shell (`MainTabView`), Today dashboard |
| **DesignSystem** | Warehouse-friendly typography, large actions, status chips |
| **Core** | `AppEnvironment`, `FeatureFlags`, minimal shared models |
| **Networking** | Async `APIClient` with `/health` and WMS path constants |
| **Persistence** | In-memory `OfflineSyncStore` — no Core Data/SwiftData yet |
| **Scanner** | Fake frame + “Simulate Scan” — `liveScannerEnabled` is false |
| **Inbound/Outbound/Inventory** | SwiftUI + `@Observable` ViewModels with stub data |

## Current stub state

- All primary screens render **demo data** locally.
- `APIClient.healthCheck()` probes `/health` but screens do not depend on it.
- Scanner does not use AVFoundation.
- Inspection and payments are gated off via `FeatureFlags`.
- Tasks and Exceptions are navigation placeholders from Settings.

## Planned next phase (1A)

**Appointments + Inbound Receiving UI data flow**

- Wire `AppointmentsViewModel` / `ReceivingViewModel` to DockWalk API DTOs  
- Map API errors to field-friendly banners  
- Persist queued actions beyond in-memory (evaluate SwiftData)  
- Deep-link Today quick actions into Receive / Ship tabs  
