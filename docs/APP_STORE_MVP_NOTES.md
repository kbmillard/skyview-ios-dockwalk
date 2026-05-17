# DockWalk — App Store MVP notes

## Goal

Ship a **credible WMS field app** on the App Store for receiving orgs (3PLs, regional DCs) who need dock-grade software without enterprise WMS pricing or implementation timelines.

## Positioning

- **Scanner-first** — large tap targets, fast scan flows, minimal chrome  
- **Shift-long usability** — readable outdoors, calm instrument UI, obvious status  
- **Inbound + outbound + inventory** as the daily loop — not a generic “business app”  

## Intentionally not in foundation build

| Area | Status |
|------|--------|
| Live AVFoundation / hardware scanner | Later phase |
| Gemini / AI damage inspection | Flag off; stub screen only |
| POS / PaymentManager / processor SDKs | Flag off; not started |
| Full API sync | Health probe only; stub ViewModels |
| SiteWalk code or shared camera spike | Out of scope for this repo |

## App access vs dock fees (product)

- **App subscription** → Apple IAP (receiving org)  
- **Lumper / unload fees on dock** → receiver-linked PSP capture (future); not driver Stripe IAP  

Keep marketing and in-app copy aligned with that split.

## Before TestFlight / App Store

- App icon and screenshots showing Today / Receive / Ship  
- Privacy policy covering facility and scan metadata  
- Export compliance and camera usage strings when live camera ships  
- Bundle ID: `io.skyprairie.dockwalk`  
