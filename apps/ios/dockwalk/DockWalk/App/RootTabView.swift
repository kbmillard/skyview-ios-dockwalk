import SwiftUI

/// Three-tab bottom bar with floating scan disc
/// TODO(design): Move and Me tabs are shells - need content design
/// TODO(design): Receive/Putaway/Ship flows should live inside Move, not as separate tabs
struct RootTabView: View {
    @State private var selectedTab: RootTab = .today
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Tab content
            tabContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Custom bottom tab bar with floating scan disc
            customTabBar
        }
        .background(Tokens.Color.Surface.canvas.ignoresSafeArea())
    }
    
    // MARK: - Tab Content
    
    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .today:
            TodayDashboard(selectedTab: .constant(.today))
        case .move:
            moveStubView
        case .me:
            meStubView
        }
    }
    
    // TODO(design): Move tab should contain Receive/Putaway/Ship flows
    private var moveStubView: some View {
        VStack(spacing: Tokens.Space.lg) {
            Image(systemName: "arrow.left.arrow.right")
                .font(.system(size: 64, weight: .thin))
                .foregroundStyle(Tokens.Color.Ink.tertiary)
            Text("Move")
                .font(Tokens.Font.titleSection)
                .foregroundStyle(Tokens.Color.Ink.primary)
            Text("Receive, Putaway, and Ship workflows")
                .font(Tokens.Font.bodySecondary)
                .foregroundStyle(Tokens.Color.Ink.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(Tokens.Space.xxxl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Tokens.Color.Surface.canvas)
    }
    
    // TODO(design): Me tab should contain Settings, Profile, Help
    private var meStubView: some View {
        VStack(spacing: Tokens.Space.lg) {
            Image(systemName: "person.crop.circle")
                .font(.system(size: 64, weight: .thin))
                .foregroundStyle(Tokens.Color.Ink.tertiary)
            Text("Me")
                .font(Tokens.Font.titleSection)
                .foregroundStyle(Tokens.Color.Ink.primary)
            Text("Settings, Profile, and Help")
                .font(Tokens.Font.bodySecondary)
                .foregroundStyle(Tokens.Color.Ink.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(Tokens.Space.xxxl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Tokens.Color.Surface.canvas)
    }
    
    // MARK: - Custom Tab Bar
    
    private var customTabBar: some View {
        ZStack {
            // Tab bar background
            VStack(spacing: 0) {
                Divider()
                    .frame(height: 0.5)
                    .background(Tokens.Color.Divider.hairline)
                
                HStack(spacing: 0) {
                    tabBarItem(for: .today)
                    Spacer()
                    Spacer() // Extra space for floating scan disc
                    Spacer()
                    tabBarItem(for: .me)
                }
                .padding(.horizontal, Tokens.Space.xl)
                .frame(height: Tokens.TapTarget.minimum)
                .background(Tokens.Color.Surface.card)
            }
            
            // Floating scan disc (center, half-overlapping tab bar)
            VStack {
                Spacer()
                floatingScanDisc
                    .offset(y: -Tokens.TapTarget.scanDisc / 2)
            }
        }
        .ignoresSafeArea(.keyboard)
    }
    
    private func tabBarItem(for tab: RootTab) -> some View {
        Button {
            withAnimation(Tokens.Motion.settle) {
                selectedTab = tab
            }
            Haptics.scanSuccess() // TODO(design): Should this be a lighter tap feedback?
        } label: {
            VStack(spacing: Tokens.Space.xs) {
                Image(systemName: tab.icon)
                    .font(.system(size: 24, weight: .medium))
                Text(tab.label)
                    .font(Tokens.Font.bodyMeta)
            }
            .foregroundStyle(
                selectedTab == tab ? Tokens.Color.Accent.horizon : Tokens.Color.Ink.tertiary
            )
            .frame(width: 80, height: Tokens.TapTarget.minimum)
        }
    }
    
    // TODO(design): Scan disc should trigger scanner when tapped
    // TODO(design): Need scanner integration - currently just visual
    private var floatingScanDisc: some View {
        Button {
            Haptics.scanSuccess()
            // TODO(design): Open scanner sheet
        } label: {
            ZStack {
                Circle()
                    .fill(Tokens.Color.Accent.horizon)
                    .frame(
                        width: Tokens.TapTarget.scanDisc,
                        height: Tokens.TapTarget.scanDisc
                    )
                    .shadow(
                        color: Tokens.Color.Accent.horizon.opacity(0.3),
                        radius: 12,
                        y: 4
                    )
                
                // TODO(design): Replace with SkyView emblem asset
                Image(systemName: "barcode.viewfinder")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(Tokens.Color.Ink.inverse)
            }
        }
    }
}

enum RootTab: Int, CaseIterable {
    case today
    case move
    case me
    
    var label: String {
        switch self {
        case .today: return "Today"
        case .move: return "Move"
        case .me: return "Me"
        }
    }
    
    var icon: String {
        switch self {
        case .today: return "sun.max.fill"
        case .move: return "arrow.left.arrow.right"
        case .me: return "person.crop.circle.fill"
        }
    }
}

#Preview {
    RootTabView()
        .environment(AppEnvironment.shared)
        .environment(OfflineSyncStore.shared)
}
