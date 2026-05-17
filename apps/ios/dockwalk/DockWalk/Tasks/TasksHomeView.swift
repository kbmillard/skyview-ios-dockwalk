import SwiftUI

/// Entry from **More → Putaway tasks** — delegates to the shared putaway list.
struct TasksHomeView: View {
    var body: some View {
        PutawayTasksView()
    }
}

#Preview {
    NavigationStack {
        TasksHomeView()
            .environment(AppEnvironment.shared)
    }
}
