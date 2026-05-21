import SwiftUI

/// Root picking destination on the main tab bar.
struct PickingTabRootView: View {
    var body: some View {
        NavigationStack {
            PickingTasksView()
        }
    }
}
