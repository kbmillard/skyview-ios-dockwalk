import SwiftUI

struct LiveNowBanner: View {
    let item: TodayModels.LiveNowItem
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                Image(systemName: "truck.box.fill")
                    .font(.title3)
                    .foregroundStyle(.white)
                    .frame(width: 38, height: 38)
                    .background(Color.white.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Tokens.Color.Accent.horizon)
                            .frame(width: 5, height: 5)
                        Text("LIVE NOW · \(item.door.uppercased())")
                            .font(.system(size: 9, design: .monospaced).weight(.semibold))
                            .foregroundStyle(Color(red: 0.53, green: 0.67, blue: 0.83))
                    }
                    Text(item.title)
                        .font(Tokens.Font.titleCard)
                        .foregroundStyle(.white)
                    Text(item.subtitle)
                        .font(Tokens.Font.bodySecondary)
                        .foregroundStyle(Color(white: 0.66))
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.4))
            }
            .padding(14)
            .background {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(red: 0.04, green: 0.08, blue: 0.16))
            }
        }
        .buttonStyle(.plain)
    }
}
