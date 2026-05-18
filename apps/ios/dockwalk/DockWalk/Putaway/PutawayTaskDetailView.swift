import SwiftUI

struct PutawayTaskDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppEnvironment.self) private var environment

    let initialTask: PutawayTaskItem
    var onTaskUpdated: (() -> Void)?

    @State private var viewModel: PutawayTaskDetailViewModel?
    @State private var showBlockSheet = false
    @State private var blockReasonOption: PutawayBlockReasonOption = .locationBlocked
    @State private var blockReasonText = PutawayBlockReasonOption.locationBlocked.defaultReasonText
    @State private var showCompleteConfirm = false
    @State private var completeQuantityText = "1"
    @State private var showLabelScanner = false
    @State private var scannedLabelContext: String?

    var body: some View {
        NavigationStack {
            Group {
                if let viewModel, viewModel.loadPhase == .loaded, let detail = viewModel.task {
                    detailContent(viewModel, detail: detail)
                } else if let viewModel {
                    LoadStateView(phase: viewModel.loadPhase) {
                        Task { await viewModel.load() }
                    }
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Task detail")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showBlockSheet) {
                blockReasonSheet
            }
            .confirmationDialog(
                "Complete putaway?",
                isPresented: $showCompleteConfirm,
                titleVisibility: .visible
            ) {
                Button("Complete task", role: .destructive) {
                    submitComplete()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                completeConfirmMessage
            }
            .onAppear { ensureViewModel() }
            .task {
                ensureViewModel()
                await viewModel?.load()
            }
            .sheet(isPresented: $showLabelScanner) {
                BarcodeScannerSheet(title: "Scan label") { result in
                    scannedLabelContext = "\(result.symbology): \(result.value)"
                }
            }
        }
    }

    private func ensureViewModel() {
        if viewModel == nil {
            let vm = PutawayTaskDetailViewModel(
                taskId: initialTask.id,
                initialTask: initialTask,
                environment: environment
            )
            vm.onTaskUpdated = onTaskUpdated
            viewModel = vm
        }
    }

    @ViewBuilder
    private func detailContent(_ viewModel: PutawayTaskDetailViewModel, detail: PutawayTaskItem) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerRow(viewModel, detail: detail)

                if let message = viewModel.actionBannerMessage {
                    StatusChip(label: message, tone: viewModel.actionBannerTone.statusChipTone)
                }

                if let scannedLabelContext {
                    StatusChip(label: "Scanned: \(scannedLabelContext)", tone: .neutral)
                }

                labeledSection("SKU") {
                    detailRow("SKU", detail.sku)
                    detailRow("Description", detail.description)
                    detailRow("Quantity", "\(formatQuantity(detail.quantity)) \(detail.uom)")
                    detailRow("Status", detail.statusDisplay)
                }

                labeledSection("Locations") {
                    detailRow("From", detail.fromLocationCode)
                    detailRow("To", detail.toLocationCode)
                }

                if let shipmentId = detail.inboundShipmentId {
                    labeledSection("Inbound") {
                        Text(shipmentId)
                            .font(.system(.body, design: .monospaced))
                            .foregroundStyle(DockWalkTheme.textPrimary)
                    }
                }

                if let created = detail.createdAt {
                    labeledSection("Timestamps") {
                        detailRow(
                            "Created",
                            created.formatted(date: .abbreviated, time: .shortened)
                        )
                    }
                }

                actionsSection(viewModel, detail: detail)
            }
            .padding()
        }
        .background(DockWalkTheme.background)
    }

    @ViewBuilder
    private func headerRow(_ viewModel: PutawayTaskDetailViewModel, detail: PutawayTaskItem) -> some View {
        HStack {
            StatusChip(label: detail.statusDisplay, tone: statusTone(detail.status))
            Spacer()
            if let mode = viewModel.dataMode {
                StatusChip(
                    label: mode == "live" ? "Live task" : "Stub API",
                    tone: mode == "live" ? .success : .neutral
                )
            }
        }
    }

    @ViewBuilder
    private func actionsSection(_ viewModel: PutawayTaskDetailViewModel, detail: PutawayTaskItem) -> some View {
        let actions = viewModel.availableActions
        if actions.isEmpty {
            labeledSection("Actions") {
                Text("No actions for \(detail.statusDisplay.lowercased()) tasks.")
                    .font(DockWalkTheme.captionFont)
                    .foregroundStyle(DockWalkTheme.textSecondary)
            }
        } else {
            VStack(alignment: .leading, spacing: 12) {
                Text("Actions")
                    .font(DockWalkTheme.headlineFont)
                if FeatureFlags.liveScannerEnabled {
                    PrimaryActionButton(title: "Scan label", systemImage: "barcode.viewfinder", style: .secondary) {
                        showLabelScanner = true
                    }
                }
                ForEach(actions) { action in
                    actionButton(viewModel, action: action, taskStatus: detail.status)
                }
                Text("Actions sync when online. If connection fails, they queue for sync (More → Sync or Debug replay). Cancel is not available yet.")
                    .font(DockWalkTheme.captionFont)
                    .foregroundStyle(DockWalkTheme.textSecondary)
            }
        }
    }

    @ViewBuilder
    private func actionButton(
        _ viewModel: PutawayTaskDetailViewModel,
        action: PutawayTaskActionKind,
        taskStatus: String
    ) -> some View {
        let title = action.dockTitle(for: taskStatus)
        let isLoading = viewModel.submittingAction == action
        let style: PrimaryActionButton.Style = action == .complete ? .primary : (action == .block ? .secondary : .primary)

        PrimaryActionButton(
            title: isLoading ? "\(title)…" : title,
            systemImage: action.systemImage,
            style: style
        ) {
            handleActionTap(viewModel, action: action)
        }
        .disabled(viewModel.isSubmittingAction)
        .opacity(viewModel.isSubmittingAction && !isLoading ? 0.5 : 1)
    }

    private func handleActionTap(_ viewModel: PutawayTaskDetailViewModel, action: PutawayTaskActionKind) {
        switch action {
        case .block:
            blockReasonOption = .locationBlocked
            blockReasonText = PutawayBlockReasonOption.locationBlocked.defaultReasonText
            showBlockSheet = true
        case .complete:
            completeQuantityText = formatQuantity(viewModel.defaultCompleteQuantity)
            showCompleteConfirm = true
        case .assign:
            Task { await viewModel.assignTask() }
        case .start:
            Task { await viewModel.startTask() }
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
                        if newValue == .other {
                            if blockReasonText == PutawayBlockReasonOption.locationBlocked.defaultReasonText
                                || blockReasonText == PutawayBlockReasonOption.productDamaged.defaultReasonText
                                || blockReasonText == PutawayBlockReasonOption.missingItem.defaultReasonText {
                                blockReasonText = ""
                            }
                        } else {
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
                            await viewModel?.blockTask(
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

    private var completeConfirmMessage: Text {
        if let task = viewModel?.task {
            let expected = formatQuantity(task.quantity)
            return Text(
                "Submit \(completeQuantityText.trimmingCharacters(in: .whitespaces)) of \(expected) \(task.uom) as completed on the server. This cannot be undone from the app."
            )
        }
        return Text("This marks the task completed on the server.")
    }

    private func submitComplete() {
        let trimmed = completeQuantityText.trimmingCharacters(in: .whitespacesAndNewlines)
        let qty = Double(trimmed) ?? viewModel?.defaultCompleteQuantity ?? 1
        Task { await viewModel?.completeTask(quantityCompleted: qty) }
    }

    @ViewBuilder
    private func labeledSection<Content: View>(_ title: String, @ViewBuilder content: @escaping () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(DockWalkTheme.headlineFont)
            SectionCard(content: content)
        }
    }

    @ViewBuilder
    private func detailRow(_ label: String, _ value: String) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .font(DockWalkTheme.captionFont)
                .foregroundStyle(DockWalkTheme.textSecondary)
                .frame(width: 88, alignment: .leading)
            Text(value)
                .font(DockWalkTheme.bodyFont)
                .foregroundStyle(DockWalkTheme.textPrimary)
            Spacer(minLength: 0)
        }
    }

    private func statusTone(_ status: String) -> StatusChip.Tone {
        switch status {
        case "completed": return .success
        case "in_progress", "assigned": return .info
        case "blocked": return .warning
        case "cancelled": return .neutral
        default: return .warning
        }
    }

    private func formatQuantity(_ value: Double) -> String {
        value == floor(value) ? String(Int(value)) : String(value)
    }
}
