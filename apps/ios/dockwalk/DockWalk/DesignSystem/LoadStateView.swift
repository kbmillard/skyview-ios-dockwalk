import SwiftUI

struct LoadStateView: View {
    let phase: LoadPhase
    var onRetry: (() -> Void)?

    var body: some View {
        switch phase {
        case .idle, .loaded:
            EmptyView()
        case .loading:
            VStack(spacing: 12) {
                ProgressView()
                Text("Loading…")
                    .font(DockWalkTheme.captionFont)
                    .foregroundStyle(DockWalkTheme.textSecondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .empty(let message):
            ContentUnavailableView(
                "Nothing here yet",
                systemImage: "tray",
                description: Text(message ?? "No records returned from DockWalk API.")
            )
        case .error(let message):
            ContentUnavailableView {
                Label("Couldn’t load", systemImage: "wifi.exclamationmark")
            } description: {
                Text(message)
            } actions: {
                if let onRetry {
                    Button("Try again", action: onRetry)
                }
            }
        }
    }
}

#Preview {
    LoadStateView(phase: .error(message: "Connection refused"), onRetry: {})
}
