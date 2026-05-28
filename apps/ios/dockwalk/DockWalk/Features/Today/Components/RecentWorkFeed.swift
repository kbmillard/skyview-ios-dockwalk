import SwiftUI

struct RecentWorkFeed: View {
    let items: [TodayModels.RecentActivityItem]

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                HStack(alignment: .top, spacing: 12) {
                    icon(for: item.tone)
                        .frame(width: 32, height: 32)

                    VStack(alignment: .leading, spacing: 2) {
                        if let barcode = item.barcode {
                            Text(barcode)
                                .font(.system(size: 13, design: .monospaced).weight(.medium))
                                .foregroundStyle(Tokens.Color.Ink.primary)
                        }
                        Text(item.title)
                            .font(Tokens.Font.titleCard)
                            .foregroundStyle(Tokens.Color.Ink.primary)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(item.meta)
                            .font(Tokens.Font.bodySecondary)
                            .foregroundStyle(Tokens.Color.Ink.secondary)
                    }

                    Spacer(minLength: 8)

                    Text(item.timeLabel)
                        .font(.system(size: 11, design: .monospaced).weight(item.isLive ? .semibold : .regular))
                        .foregroundStyle(item.isLive ? Tokens.Color.Accent.horizon : Tokens.Color.Ink.tertiary)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)

                if index < items.count - 1 {
                    Divider()
                        .padding(.leading, 58)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: Tokens.Radius.card, style: .continuous)
                .fill(Tokens.Color.Surface.card)
                .overlay {
                    RoundedRectangle(cornerRadius: Tokens.Radius.card, style: .continuous)
                        .strokeBorder(Tokens.Color.Divider.hairline, lineWidth: 0.5)
                }
        )
    }

    @ViewBuilder
    private func icon(for tone: TodayModels.RecentActivityItem.FeedTone) -> some View {
        let (name, fg, bg): (String, Color, Color) = {
            switch tone {
            case .ok: return ("checkmark", Tokens.Color.Signal.success, Tokens.Color.Signal.success.opacity(0.12))
            case .info: return ("truck.box", Tokens.Color.Accent.horizon, Tokens.Color.Accent.horizonSoft)
            case .warn: return ("exclamationmark.triangle", Tokens.Color.Signal.warning, Tokens.Color.Signal.warning.opacity(0.14))
            case .muted: return ("arrow.left.arrow.right", Tokens.Color.Ink.tertiary, Tokens.Color.Surface.elevated)
            case .pending: return ("arrow.triangle.2.circlepath", Tokens.Color.Signal.warning, Tokens.Color.Signal.warning.opacity(0.14))
            }
        }()

        Image(systemName: name)
            .font(.caption.weight(.semibold))
            .foregroundStyle(fg)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(bg)
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
