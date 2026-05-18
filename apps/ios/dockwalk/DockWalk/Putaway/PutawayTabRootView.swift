import SwiftUI

/// Root putaway destination on the main tab bar.
struct PutawayTabRootView: View {
    var body: some View {
        NavigationStack {
            PutawayTasksView(isOperationalTabRoot: true)
        }
    }
}
