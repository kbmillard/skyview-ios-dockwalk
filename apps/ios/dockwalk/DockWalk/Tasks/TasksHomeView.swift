import SwiftUI

/// Legacy wrapper — prefer `PutawayTasksView()` from **More → Modules → Putaway tasks**.
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
