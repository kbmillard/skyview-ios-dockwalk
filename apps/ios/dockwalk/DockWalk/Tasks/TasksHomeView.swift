import SwiftUI

struct TasksHomeView: View {
    var body: some View {
        ContentUnavailableView(
            "Tasks",
            systemImage: "checklist",
            description: Text("Directed work — putaway, replenishment, and priority picks — will appear here in a later phase.")
        )
        .navigationTitle("Tasks")
    }
}

#Preview {
    NavigationStack {
        TasksHomeView()
    }
}
