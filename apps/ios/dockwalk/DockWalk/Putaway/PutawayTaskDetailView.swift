import SwiftUI

struct PutawayTaskDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppEnvironment.self) private var environment

    let initialTask: PutawayTaskItem
    var onTaskUpdated: (() -> Void)?

    @State private var viewModel: PutawayTaskDetailViewModel?
    @State private var showBlockSheet = false
    @State private var blockReason = ""
    @State private var showCompleteConfirm = false

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
                    Task { await viewModel?.performAction(.complete) }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This marks the task completed on the server. This cannot be undone from the app.")
            }
            .onAppear { ensureViewModel() }
            .task {
                ensureViewModel()
                await viewModel?.load()
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
        List {
            if let mode = viewModel.dataMode {
                Section {
                    StatusChip(
                        label: mode == "live" ? "Live task" : "Stub API",
                        tone: mode == "live" ? .success : .neutral
                    )
                }
            }

            if let message = viewModel.actionBannerMessage {
                Section {
                    StatusChip(label: message, tone: viewModel.actionBannerTone.statusChipTone)
                }
            }

            Section("SKU") {
                LabeledContent("SKU", value: detail.sku)
                LabeledContent("Description", value: detail.description)
                LabeledContent("Quantity", value: "\(formatQuantity(detail.quantity)) \(detail.uom)")
                LabeledContent("Status", value: detail.statusDisplay)
            }

            Section("Locations") {
                LabeledContent("From", value: detail.fromLocationCode)
                LabeledContent("To", value: detail.toLocationCode)
            }

            if let shipmentId = detail.inboundShipmentId {
                Section("Inbound") {
                    LabeledContent("Shipment ID", value: shipmentId)
                        .font(.system(.body, design: .monospaced))
                }
            }

            if let created = detail.createdAt {
                Section("Timestamps") {
                    LabeledContent("Created", value: created.formatted(date: .abbreviated, time: .shortened))
                }
            }

            let actions = viewModel.availableActions
            if !actions.isEmpty {
                Section {
                    ForEach(actions) { action in
                        actionButton(viewModel, action: action)
                    }
                } header: {
                    Text("Actions")
                } footer: {
                    Text("Online only — task actions are not queued offline. Cancel is not available yet.")
                        .font(DockWalkTheme.captionFont)
                }
            } else {
                Section {
                    Text("No actions for \(detail.statusDisplay.lowercased()) tasks.")
                        .font(DockWalkTheme.captionFont)
                        .foregroundStyle(DockWalkTheme.textSecondary)
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    @ViewBuilder
    private func actionButton(_ viewModel: PutawayTaskDetailViewModel, action: PutawayTaskActionKind) -> some View {
        Button {
            handleActionTap(viewModel, action: action)
        } label: {
            Label(action.title, systemImage: action.systemImage)
        }
        .disabled(viewModel.isSubmittingAction)
    }

    private func handleActionTap(_ viewModel: PutawayTaskDetailViewModel, action: PutawayTaskActionKind) {
        switch action {
        case .block:
            blockReason = ""
            showBlockSheet = true
        case .complete:
            showCompleteConfirm = true
        case .assign, .start:
            Task { await viewModel.performAction(action) }
        }
    }

    private var blockReasonSheet: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Reason", text: $blockReason, axis: .vertical)
                        .lineLimit(3...6)
                } footer: {
                    Text("Required by the API (reason_code is sent as \"other\").")
                        .font(DockWalkTheme.captionFont)
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
                        Task { await viewModel?.performAction(.block, blockReason: blockReason) }
                    }
                    .disabled(blockReason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func formatQuantity(_ value: Double) -> String {
        value == floor(value) ? String(Int(value)) : String(value)
    }
}
