import SwiftUI

/// Root shipping destination on the main tab bar (picking queue + load/stage workflow).
struct ShippingTabRootView: View {
    var body: some View {
        NavigationStack {
            ShippingHomeView()
        }
    }
}
