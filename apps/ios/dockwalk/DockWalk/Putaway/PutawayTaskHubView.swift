import SwiftUI

/// Push-navigated work hub for a single putaway UPC card.
struct PutawayTaskHubView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppEnvironment.self) private var environment
    @Environment(FacilityConfigStore.self) private var facilityConfig
    @Environment(InboundSessionStore.self) private var inboundSession
    @Environment(InventoryCatalogStore.self) private var inventoryCatalog
    @Environment(PutawayCompletionStore.self) private var completionStore
    @Environment(OfflineSyncStore.self) private var syncStore
    @Environment(PutawaySessionStore.self) private var sessionStore
    @Environment(PutawayScannerCoordinator.self) private var putawayCoordinator

    let initialTask: PutawayTaskItem
    var onTaskUpdated: (() -> Void)?

    @State private var detailVM: PutawayTaskDetailViewModel?
    @State private var hubVM: PutawayTaskHubViewModel?
    @State private var movementError: String?

    @State private var showScanner = false
    @State private var pendingStep: PutawayConfirmStep = .toLocation
    @State private var pendingScannedValue: String = ""
    @State private var showConfirmView = false
    @State private var showBlockSheet = false
    @State private var blockReasonOption: PutawayBlockReasonOption = .locationBlocked
    @State private var blockReasonText = PutawayBlockReasonOption.locationBlocked.defaultReasonText

    private var isLocalCard: Bool {
        initialTask.source == .receiveSession || initialTask.source == .catalog
    }

    var body: some View {
        Group {
            if isLocalCard {
                localContent
            } else if let detailVM, let hubVM, detailVM.loadPhase == .loaded, let task = detailVM.task {
                apiContent(detailVM: detailVM, hubVM: hubVM, task: task)
            } else if let detailVM {
                LoadStateView(phase: detailVM.loadPhase) {
                    Task { await detailVM.load() }
                }
            } else {
                ProgressView()
            }
        }
        .navigationTitle(isLocalCard ? "Putaway" : "Putaway \(initialTask.sku)")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            ensureViewModels()
            putawayCoordinator.setPutawayHubActive(true)
        }
        .onDisappear {
            putawayCoordinator.setPutawayHubActive(false)
        }
        .task {
            if !isLocalCard {
                ensureViewModels()
                await detailVM?.load()
            } else if hubVM == nil {
                hubVM = PutawayTaskHubViewModel(cardId: initialTask.id, sessionStore: sessionStore)
            }
        }
        .onChange(of: putawayCoordinator.openScannerToken) { _, _ in
            guard putawayCoordinator.isPutawayHubActive else { return }
            pendingStep = putawayCoordinator.requestedStep ?? .toLocation
            showScanner = true
        }
        .sheet(isPresented: $showScanner) {
            BarcodeScannerSheet(title: pendingStep.scanTitle) { result in
                pendingScannedValue = result.value
                if isLocalCard && pendingStep == .toLocation {
                    showScanner = false
                    Task { await completeLocalPutaway(scannedBin: result.value) }
                } else {
                    showConfirmView = true
                }
            }
        }
        .sheet(isPresented: $showConfirmView) {
            if let task = detailVM?.task ?? Optional(initialTask) {
                PutawayConfirmView(
                    task: task,
                    step: pendingStep,
                    initialScannedValue: pendingScannedValue
                )
            }
        }
        .sheet(isPresented: $showBlockSheet) {
            blockReasonSheet
        }
    }

    private var localContent: some View {
        let card = initialTask
        let hubVM = hubVM ?? PutawayTaskHubViewModel(cardId: card.id, sessionStore: sessionStore)
        return ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ScannerLockChip(mode: .putawayTask(taskId: card.id))
                PutawayHubSnapshot(
                    card: card,
                    savedStepCount: hubVM.saved(.toLocation) != nil ? 1 : 0,
                    totalSteps: 1
                )
                Text(card.upc)
                    .font(.system(.title3, design: .monospaced).weight(.semibold))
                if let sku = card.secondarySKULabel {
                    Text(sku)
                        .font(DockWalkTheme.captionFont)
                        .foregroundStyle(DockWalkTheme.textSecondary)
                }
                PrimaryActionButton(title: "Scan storage bin", systemImage: "barcode.viewfinder") {
                    pendingStep = .toLocation
                    pendingScannedValue = ""
                    showScanner = true
                }
                if case .syncing = facilityConfig.locationsSyncPhase {
                    Text("Syncing locations…")
                        .font(DockWalkTheme.captionFont)
                        .foregroundStyle(DockWalkTheme.warning)
                }
                if let movementError {
                    Text(movementError)
                        .font(DockWalkTheme.captionFont)
                        .foregroundStyle(DockWalkTheme.warning)
                }
            }
            .padding(DockWalkTheme.screenPadding)
        }
        .background(DockWalkTheme.background)
    }

    private func completeLocalPutaway(scannedBin: String) async {
        movementError = nil
        let result = await PutawayMovementService.apply(
            card: initialTask,
            toLocation: scannedBin,
            facilityConfig: facilityConfig,
            inboundSession: inboundSession,
            catalog: inventoryCatalog,
            completionStore: completionStore,
            syncStore: syncStore,
            environment: environment
        )
        switch result {
        case .success:
            onTaskUpdated?()
            dismiss()
        case .failure(let error):
            movementError = error.localizedDescription
        }
    }

    private func ensureViewModels() {
        if detailVM == nil, !isLocalCard {
            let vm = PutawayTaskDetailViewModel(
                taskId: initialTask.id,
                initialTask: initialTask,
                environment: environment
            )
            vm.onTaskUpdated = onTaskUpdated
            detailVM = vm
        }
        if hubVM == nil {
            hubVM = PutawayTaskHubViewModel(cardId: initialTask.id, sessionStore: sessionStore)
        }
    }

    @ViewBuilder
    private func apiContent(
        detailVM: PutawayTaskDetailViewModel,
        hubVM: PutawayTaskHubViewModel,
        task: PutawayTaskItem
    ) -> some View {
        let _ = sessionStore.revision
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ScannerLockChip(mode: .putawayTask(taskId: task.id))
                if let message = detailVM.actionBannerMessage {
                    StatusChip(label: message, tone: detailVM.actionBannerTone.statusChipTone)
                }
                PutawayHubSnapshot(
                    card: task,
                    savedStepCount: hubVM.savedDrafts.count,
                    totalSteps: PutawayConfirmStep.allCases.count
                )
                apiStepsSection(task: task, hubVM: hubVM)
                apiActionsCluster(detailVM: detailVM, task: task, hubVM: hubVM)
            }
            .padding(DockWalkTheme.screenPadding)
        }
        .background(DockWalkTheme.background)
    }

    @ViewBuilder
    private func apiStepsSection(task: PutawayTaskItem, hubVM: PutawayTaskHubViewModel) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Confirm steps")
                .font(DockWalkTheme.headlineFont)
            ForEach(PutawayConfirmStep.allCases) { step in
                if let draft = hubVM.saved(step) {
                    PutawayStepBubbleRow(draft: draft, expectedValue: expected(for: step, task: task)) {
                        pendingStep = step
                        pendingScannedValue = draft.scannedValue
                        showConfirmView = true
                    }
                } else {
                    apiStepPlaceholder(step)
                }
            }
        }
    }

    private func apiStepPlaceholder(_ step: PutawayConfirmStep) -> some View {
        Button {
            pendingStep = step
            pendingScannedValue = ""
            if step == .quantity {
                showConfirmView = true
            } else {
                showScanner = true
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: step.systemImage)
                    .foregroundStyle(DockWalkTheme.textSecondary)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text(step.displayName)
                        .font(DockWalkTheme.bodyFont.weight(.semibold))
                    Text(step == .quantity ? "Tap to confirm qty" : "Tap to scan")
                        .font(DockWalkTheme.captionFont)
                        .foregroundStyle(DockWalkTheme.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(DockWalkTheme.textSecondary)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
            .background(DockWalkTheme.cardBackground.opacity(0.6))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func expected(for step: PutawayConfirmStep, task: PutawayTaskItem) -> String? {
        switch step {
        case .fromLocation: return task.fromLocationCode
        case .toLocation: return task.toLocationCode
        case .upc: return task.upc
        case .quantity: return nil
        }
    }

    @ViewBuilder
    private func apiActionsCluster(
        detailVM: PutawayTaskDetailViewModel,
        task: PutawayTaskItem,
        hubVM: PutawayTaskHubViewModel
    ) -> some View {
        VStack(spacing: 12) {
            CompletePutawayButton(isEnabled: hubVM.canComplete(for: task)) {
                let qty = hubVM.confirmedQuantity(for: task)
                Task {
                    await detailVM.completeTask(quantityCompleted: qty)
                    if detailVM.task?.status == .completed {
                        hubVM.clearSession()
                        onTaskUpdated?()
                        dismiss()
                    }
                }
            }
            HStack(spacing: 12) {
                if detailVM.availableActions.contains(.assign) {
                    PrimaryActionButton(title: "Assign", systemImage: "person.crop.circle", style: .secondary) {
                        Task { await detailVM.assignTask() }
                    }
                }
                if detailVM.availableActions.contains(.start) {
                    PrimaryActionButton(title: "Start", systemImage: "play.fill", style: .secondary) {
                        Task { await detailVM.startTask() }
                    }
                }
                if detailVM.availableActions.contains(.block) {
                    PrimaryActionButton(title: "Block", systemImage: "exclamationmark.triangle", style: .secondary) {
                        blockReasonOption = .locationBlocked
                        blockReasonText = PutawayBlockReasonOption.locationBlocked.defaultReasonText
                        showBlockSheet = true
                    }
                }
            }
        }
    }

    private var blockReasonSheet: some View {
        NavigationStack {
            Form {
                Section("Reason") {
                    Picker("Category", selection: $blockReasonOption) {
                        ForEach(PutawayBlockReasonOption.allCases) { option in
                            Text(option.label).tag(option)
                        }
                    }
                    .pickerStyle(.inline)
                    .onChange(of: blockReasonOption) { _, newValue in
                        if newValue != .other {
                            blockReasonText = newValue.defaultReasonText
                        }
                    }
                    TextField("Details", text: $blockReasonText, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Block task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showBlockSheet = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Submit") {
                        showBlockSheet = false
                        Task {
                            await detailVM?.blockTask(
                                reasonCode: blockReasonOption.rawValue,
                                reason: blockReasonText
                            )
                        }
                    }
                    .disabled(blockReasonText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .presentationDetents([.large])
    }
}
