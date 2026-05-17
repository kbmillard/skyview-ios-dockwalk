import SwiftUI

@main
struct DockWalkApp: App {
    @State private var environment = AppEnvironment.shared
    @State private var syncStore = OfflineSyncStore.shared

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environment(environment)
                .environment(syncStore)
        }
    }
}
