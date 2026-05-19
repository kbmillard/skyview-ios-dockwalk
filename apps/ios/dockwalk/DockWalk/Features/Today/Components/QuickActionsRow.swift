import SwiftUI

struct QuickActionsRow: View {
    let actions: [MockWarehouseFloor.QuickAction]
    var onSelect: (AppTab) -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 4)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(actions) { action in
                Button {
                    onSelect(action.tab)
                } label: {
                    VStack(spacing: 8) {
                        Image(systemName: action.systemImage)
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(width: 32, height: 32)
                            .background(Color(red: 0.04, green: 0.08, blue: 0.16))
                            .clipShape(RoundedRectangle(cornerRadius: 10))

                        Text(action.title)
                            .font(.system(size: 10.5, weight: .semibold))
                            .foregroundStyle(Tokens.Color.Ink.primary)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .minimumScaleFactor(0.85)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .padding(.horizontal, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Tokens.Color.Surface.card)
                            .overlay {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .strokeBorder(Tokens.Color.Divider.hairline, lineWidth: 0.5)
                            }
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

#Preview {
    QuickActionsRow(actions: MockWarehouseFloor.quickActions) { _ in }
        .padding()
}
