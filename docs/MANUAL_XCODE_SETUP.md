# Manual Xcode setup (if needed)

The repo includes `apps/ios/dockwalk/DockWalk.xcodeproj`, generated from `apps/ios/dockwalk/project.yml` via [XcodeGen](https://github.com/yonaskolb/XcodeGen).

Regenerate after adding/removing source files:

```bash
cd apps/ios/dockwalk
xcodegen generate
```

Use the steps below only if you need to recreate the project without XcodeGen.

## Create project

1. **File → New → Project → iOS → App**
2. Product name: **DockWalk**
3. Interface: **SwiftUI**
4. Language: **Swift**
5. Bundle identifier: **io.skyprairie.dockwalk**
6. Save under `apps/ios/dockwalk/` (alongside the existing `DockWalk/` source folder)

## Add existing sources

1. Delete the template `ContentView.swift` and default app file if duplicated.
2. Drag the existing `DockWalk/` folder into the project (create groups, copy items if needed).
3. Ensure **DockWalkApp.swift** is the only `@main` entry.
4. Add `Resources/Assets.xcassets` and set **App Icon** source.
5. Set **Info.plist** to `DockWalk/Resources/Info.plist` if not auto-detected.

## Test target

1. **File → New → Target → Unit Testing Bundle** named `DockWalkTests`
2. Add `DockWalkTests/DockWalkFoundationTests.swift`
3. Enable **@testable import DockWalk** on the test target

## Build

1. Scheme: **DockWalk**
2. Destination: any iOS Simulator
3. **Product → Build** (⌘B)

Command line:

```bash
cd apps/ios/dockwalk
xcodebuild -project DockWalk.xcodeproj -scheme DockWalk \
  -destination 'generic/platform=iOS' build CODE_SIGNING_ALLOWED=NO
```

## Do not

- Import **SiteWalk** or **SkyViewCameraSpike** targets  
- Rename the app to SiteWalk  
- Add API or Supabase code to this repo  
