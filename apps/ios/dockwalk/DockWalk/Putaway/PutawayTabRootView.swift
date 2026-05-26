import SwiftUI

/// Root putaway destination on the main tab bar.
struct PutawayTabRootView: View {
    @Environment(PutawayScannerCoordinator.self) private var putawayCoordinator
    @Environment(ScannerPreferencesStore.self) private var scannerPreferences

    @State private var scanUPCPending: String?
    @State private var showScanner = false
    @State private var showNotFoundAlert = false
    @State private var navigationCard: PutawayUPCCard?
    @State private var lastHandledScanToken = 0

    var body: some View {
        NavigationStack {
            PutawayTasksView(isOperationalTabRoot: true)
                .navigationDestination(item: $navigationCard) { card in
                    PutawayTaskHubView(initialTask: card)
                }
        }
        .onAppear {
            putawayCoordinator.setPutawayTabActive(true)
            handleScanRequestIfNeeded()
        }
        .onDisappear {
            putawayCoordinator.setPutawayTabActive(false)
        }
        .onChange(of: putawayCoordinator.openScannerToken) { _, _ in
            handleScanRequestIfNeeded()
        }
        .sheet(isPresented: $showScanner) {
            BarcodeScannerSheet(title: "Scan UPC") { result in
                scanUPCPending = result.value
                showScanner = false
            }
        }
        .onChange(of: showScanner) { _, isShowing in
            guard !isShowing, let code = scanUPCPending else { return }
            scanUPCPending = nil
            resolveAndNavigate(upc: code)
        }
        .alert("No pending putaway", isPresented: $showNotFoundAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("No open putaway card for that UPC. Receive on a load first.")
        }
    }

    private func handleScanRequestIfNeeded() {
        let token = putawayCoordinator.openScannerToken
        guard token != lastHandledScanToken else { return }
        lastHandledScanToken = token
        guard putawayCoordinator.isPutawayTabActive, !putawayCoordinator.isPutawayHubActive else { return }
        guard scannerPreferences.isScannerActive else { return }
        showScanner = true
    }

    private func resolveAndNavigate(upc: String) {
        if let card = PutawayCardResolver.resolve(upc: upc) {
            navigationCard = card
        } else {
            showNotFoundAlert = true
        }
    }
}
