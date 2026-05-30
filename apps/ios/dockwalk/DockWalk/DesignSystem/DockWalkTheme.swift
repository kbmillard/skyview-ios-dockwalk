import Foundation
import Observation
import SwiftUI

enum DockWalkTheme {
    static let screenPadding: CGFloat = 16
    static let sectionSpacing: CGFloat = 20
    static let cornerRadius: CGFloat = 14

    private static var palette: ThemePalette { ThemeStore.shared.palette }

    static var background: Color { palette.background }
    static var cardBackground: Color { palette.cardBackground }
    static var cardBorder: Color { palette.cardBorder }
    static var accent: Color { palette.accent }
    static var accentMuted: Color { palette.accentMuted }
    static var textPrimary: Color { palette.textPrimary }
    static var textSecondary: Color { palette.textSecondary }
    static var success: Color { palette.success }
    static var warning: Color { palette.warning }
    static var danger: Color { palette.danger }
    static var note: Color { palette.note }

    static let titleFont = Font.system(.title2, design: .rounded).weight(.semibold)
    static let headlineFont = Font.system(.headline, design: .rounded).weight(.semibold)
    static let subtitleFont = Font.system(.subheadline, design: .default)
    static let bodyFont = Font.system(.body, design: .default)
    static let captionFont = Font.system(.caption, design: .default)
}

enum ThemeProfile: String, CaseIterable, Codable, Identifiable {
    case dockwalkClassic = "dockwalk_classic"
    case fieldDark = "field_dark"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .dockwalkClassic: return "DockWalk Classic"
        case .fieldDark: return "Field Dark"
        }
    }
}

struct ThemePalette {
    let background: Color
    let cardBackground: Color
    let cardBorder: Color
    let accent: Color
    let accentMuted: Color
    let textPrimary: Color
    let textSecondary: Color
    let success: Color
    let warning: Color
    let danger: Color
    let note: Color
}

@Observable
final class ThemeStore {
    static let shared = ThemeStore()
    private static let profileKey = "DockWalk.ThemeProfile"

    private(set) var revision = 0
    private let defaults: UserDefaults

    var profile: ThemeProfile {
        didSet {
            defaults.set(profile.rawValue, forKey: Self.profileKey)
            revision += 1
        }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let raw = defaults.string(forKey: Self.profileKey),
           let stored = ThemeProfile(rawValue: raw) {
            profile = stored
        } else {
            profile = .dockwalkClassic
        }
    }

    func setProfile(_ profile: ThemeProfile) {
        guard self.profile != profile else { return }
        self.profile = profile
    }

    var palette: ThemePalette {
        switch profile {
        case .dockwalkClassic:
            return ThemePalette(
                background: Color(.systemGroupedBackground),
                cardBackground: Color(.secondarySystemGroupedBackground),
                cardBorder: Color.primary.opacity(0.08),
                accent: Color(red: 0.12, green: 0.45, blue: 0.78),
                accentMuted: Color(red: 0.12, green: 0.45, blue: 0.78).opacity(0.12),
                textPrimary: .primary,
                textSecondary: .secondary,
                success: .green,
                warning: .orange,
                danger: .red,
                note: Color(red: 0.47, green: 0.53, blue: 0.62)
            )
        case .fieldDark:
            return ThemePalette(
                background: Color(red: 0.051, green: 0.063, blue: 0.086),
                cardBackground: Color(red: 0.094, green: 0.110, blue: 0.146),
                cardBorder: Color(red: 0.155, green: 0.172, blue: 0.205),
                accent: Color(red: 0.122, green: 0.502, blue: 1.000),
                accentMuted: Color(red: 0.122, green: 0.502, blue: 1.000).opacity(0.14),
                textPrimary: Color(red: 0.952, green: 0.960, blue: 0.968),
                textSecondary: Color(red: 0.567, green: 0.611, blue: 0.673),
                success: Color(red: 0.166, green: 0.754, blue: 0.479),
                warning: Color(red: 0.978, green: 0.636, blue: 0.123),
                danger: Color(red: 0.903, green: 0.217, blue: 0.217),
                note: Color(red: 0.487, green: 0.540, blue: 0.613)
            )
        }
    }
}

struct LoadCardModel: Identifiable, Equatable {
    let id: String
    let title: String
    let subtitle: String?
    let statusLabel: String
    let statusTone: StatusChip.Tone
    let metaRows: [String]
}

struct UPCLineModel: Identifiable, Equatable {
    let id: String
    let upc: String
    let sku: String?
    let quantityLabel: String
    let locationLabel: String?
    let statusLabel: String
    let statusTone: StatusChip.Tone
}

struct WorkflowActionModel: Identifiable, Equatable {
    let id: String
    let title: String
    let systemImage: String
    let isPrimary: Bool
    let isEnabled: Bool
}

struct LoadCardView: View {
    let model: LoadCardModel

    var body: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top, spacing: 8) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(model.title)
                            .font(DockWalkTheme.headlineFont)
                            .foregroundStyle(DockWalkTheme.textPrimary)
                        if let subtitle = model.subtitle, !subtitle.isEmpty {
                            Text(subtitle)
                                .font(DockWalkTheme.captionFont)
                                .foregroundStyle(DockWalkTheme.textSecondary)
                        }
                    }
                    Spacer()
                    StatusChip(label: model.statusLabel, tone: model.statusTone)
                }

                ForEach(model.metaRows, id: \.self) { row in
                    Text(row)
                        .font(DockWalkTheme.captionFont)
                        .foregroundStyle(DockWalkTheme.textSecondary)
                }
            }
        }
    }
}

struct UPCCardView: View {
    let model: UPCLineModel

    var body: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(model.upc)
                        .font(.system(.body, design: .monospaced).weight(.semibold))
                        .foregroundStyle(DockWalkTheme.textPrimary)
                    Spacer()
                    StatusChip(label: model.statusLabel, tone: model.statusTone)
                }
                if let sku = model.sku, !sku.isEmpty {
                    Text(sku)
                        .font(DockWalkTheme.captionFont)
                        .foregroundStyle(DockWalkTheme.textSecondary)
                }
                HStack(spacing: 8) {
                    Text(model.quantityLabel)
                        .font(DockWalkTheme.captionFont.weight(.semibold))
                    if let location = model.locationLabel, !location.isEmpty {
                        Text("·")
                            .foregroundStyle(DockWalkTheme.textSecondary)
                        Text(location)
                            .font(DockWalkTheme.captionFont)
                            .foregroundStyle(DockWalkTheme.textSecondary)
                    }
                }
            }
        }
    }
}
