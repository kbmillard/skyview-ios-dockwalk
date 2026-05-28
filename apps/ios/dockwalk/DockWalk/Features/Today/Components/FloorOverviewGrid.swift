import SwiftUI

struct FloorOverviewGrid: View {
    let stats: [TodayModels.OverviewStat]

    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(stats) { stat in
                statCard(stat)
            }
        }
    }

    private func statCard(_ stat: TodayModels.OverviewStat) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(stat.label)
                    .font(Tokens.Font.bodyMeta)
                    .foregroundStyle(Tokens.Color.Ink.secondary)
                Spacer()
                Image(systemName: icon(for: stat.tone))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(color(for: stat.tone))
            }

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(stat.value)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(Tokens.Color.Ink.primary)
                if let sub = stat.subvalue {
                    Text(sub)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(Tokens.Color.Ink.tertiary)
                }
            }

            if let delta = stat.delta {
                Text(delta)
                    .font(Tokens.Font.bodyMeta)
                    .foregroundStyle(color(for: stat.tone))
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: Tokens.Radius.card, style: .continuous)
                .fill(Tokens.Color.Surface.card)
                .overlay {
                    RoundedRectangle(cornerRadius: Tokens.Radius.card, style: .continuous)
                        .strokeBorder(Tokens.Color.Divider.hairline, lineWidth: 0.5)
                }
        )
    }

    private func color(for tone: TodayModels.OverviewStat.StatTone) -> Color {
        switch tone {
        case .ok: return Tokens.Color.Signal.success
        case .info: return Tokens.Color.Accent.horizon
        case .warn: return Tokens.Color.Signal.warning
        case .crit: return Tokens.Color.Signal.critical
        }
    }

    private func icon(for tone: TodayModels.OverviewStat.StatTone) -> String {
        switch tone {
        case .ok: return "checkmark"
        case .info: return "arrow.down"
        case .warn: return "exclamationmark.triangle"
        case .crit: return "exclamationmark.triangle.fill"
        }
    }
}
