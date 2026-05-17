import SwiftUI

struct ExceptionsHomeView: View {
    var body: some View {
        ContentUnavailableView(
            "Exceptions",
            systemImage: "exclamationmark.triangle",
            description: Text("OS&D, shorts, overages, and damage exceptions will be tracked here.")
        )
        .navigationTitle("Exceptions")
    }
}

#Preview {
    NavigationStack {
        ExceptionsHomeView()
    }
}
