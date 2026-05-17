import SwiftUI

struct PutawayTasksView: View {
    @Environment(AppEnvironment.self) private var environment
    @State private var viewModel: PutawayTasksViewModel?
    @State private var selectedTask: PutawayTaskItem?

    private let inboundShipmentId: String?
    private let navigationTitle: String

    init(inboundShipmentId: String? = nil) {
        self.inboundShipmentId = inboundShipmentId
        self.navigationTitle = inboundShipmentId == nil ? "Putaway tasks" : "Putaway for shipment"
    }

    var body: some View {
        Group {
            if let viewModel, viewModel.loadPhase == .loaded {
                taskList(viewModel)
            } else if let viewModel {
                LoadStateView(phase: viewModel.loadPhase) {
                    Task { await viewModel.refresh() }
                }
            } else {
                ProgressView()
            }
        }
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            await viewModel?.refresh()
        }
        .sheet(item: $selectedTask) { task in
            PutawayTaskDetailSheet(task: task)
        }
        .onAppear {
            if viewModel == nil {
                viewModel = PutawayTasksViewModel(
                    environment: environment,
                    inboundShipmentId: inboundShipmentId
                )
            }
        }
        .task(id: environment.configRevision) {
            if viewModel == nil {
                viewModel = PutawayTasksViewModel(
                    environment: environment,
                    inboundShipmentId: inboundShipmentId
                )
            }
            await viewModel?.refresh()
        }
    }

    @ViewBuilder
    private func taskList(_ viewModel: PutawayTasksViewModel) -> some View {
        List {
            if let mode = viewModel.dataMode {
                Section {
                    StatusChip(
                        label: mode == "live" ? "Live tasks" : "Stub API",
                        tone: mode == "live" ? .success : .neutral
                    )
                    Text("Read-only — assign and complete are not available in this build.")
                        .font(DockWalkTheme.captionFont)
                        .foregroundStyle(DockWalkTheme.textSecondary)
                }
            }

            Section {
                statusFilterChips(viewModel)
            }

            Section {
                ForEach(viewModel.tasks) { task in
                    Button {
                        selectedTask = task
                    } label: {
                        putawayRow(task)
                    }
                    .buttonStyle(.plain)
                }

                if viewModel.canLoadMore {
                    Button {
                        Task { await viewModel.loadMore() }
                    } label: {
                        HStack {
                            Spacer()
                            if viewModel.isLoadingMore {
                                ProgressView()
                            } else {
                                Text("Load more")
                            }
                            Spacer()
                        }
                    }
                    .disabled(viewModel.isLoadingMore)
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private func statusFilterChips(_ viewModel: PutawayTasksViewModel) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(PutawayTaskStatusFilter.allCases) { filter in
                    let selected = viewModel.statusFilter == filter
                    Button {
                        Task { await viewModel.setStatusFilter(filter) }
                    } label: {
                        Text(filter.label)
                            .font(DockWalkTheme.captionFont)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(selected ? DockWalkTheme.accentMuted : DockWalkTheme.cardBackground)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.isLoadingMore && selected)
                }
            }
        }
    }

    private func putawayRow(_ task: PutawayTaskItem) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(task.sku)
                    .font(DockWalkTheme.headlineFont)
                Spacer()
                StatusChip(label: task.statusDisplay, tone: statusTone(task.status))
            }
            Text("\(formatQuantity(task.quantity)) \(task.uom)")
                .font(DockWalkTheme.bodyFont)
            Text(task.routeLabel)
                .font(DockWalkTheme.captionFont)
                .foregroundStyle(DockWalkTheme.textSecondary)
            if let shipmentId = task.inboundShipmentId {
                Text(shipmentId)
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(DockWalkTheme.textSecondary)
            }
        }
        .padding(.vertical, 4)
    }

    private func formatQuantity(_ value: Double) -> String {
        value == floor(value) ? String(Int(value)) : String(value)
    }

    private func statusTone(_ status: String) -> StatusChip.Tone {
        switch status {
        case "completed": return .success
        case "in_progress", "assigned": return .info
        case "cancelled": return .neutral
        default: return .warning
        }
    }
}

struct PutawayTaskDetailSheet: View {
    @Environment(AppEnvironment.self) private var environment
    let task: PutawayTaskItem
    @State private var viewModel: PutawayTaskDetailViewModel?

    var body: some View {
        NavigationStack {
            Group {
                if let viewModel, viewModel.loadPhase == .loaded, let detail = viewModel.task {
                    detailContent(detail, mode: viewModel.dataMode)
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
                    Button("Done") {
                        dismissSheet()
                    }
                }
            }
            .onAppear {
                if viewModel == nil {
                    viewModel = PutawayTaskDetailViewModel(
                        taskId: task.id,
                        initialTask: task,
                        environment: environment
                    )
                }
            }
            .task {
                if viewModel == nil {
                    viewModel = PutawayTaskDetailViewModel(
                        taskId: task.id,
                        initialTask: task,
                        environment: environment
                    )
                }
                await viewModel?.load()
            }
        }
    }

    @Environment(\.dismiss) private var dismiss

    private func dismissSheet() {
        dismiss()
    }

    @ViewBuilder
    private func detailContent(_ detail: PutawayTaskItem, mode: String?) -> some View {
        List {
            if let mode {
                Section {
                    StatusChip(
                        label: mode == "live" ? "Live task" : "Stub API",
                        tone: mode == "live" ? .success : .neutral
                    )
                }
            }

            Section("SKU") {
                LabeledContent("SKU", value: detail.sku)
                LabeledContent("Description", value: detail.description)
                LabeledContent("Quantity", value: "\(detail.quantity) \(detail.uom)")
                LabeledContent("Status", value: detail.statusDisplay)
            }

            Section("Locations") {
                LabeledContent("From", value: detail.fromLocationCode)
                LabeledContent("To", value: detail.toLocationCode)
            }

            if detail.inboundShipmentId != nil {
                Section("Inbound") {
                    if let shipmentId = detail.inboundShipmentId {
                        LabeledContent("Shipment ID", value: shipmentId)
                            .font(.system(.body, design: .monospaced))
                    }
                }
            }

            if let created = detail.createdAt {
                Section("Timestamps") {
                    LabeledContent("Created", value: created.formatted(date: .abbreviated, time: .shortened))
                }
            }

            Section {
                Text("Read-only — no assign or complete actions in this build.")
                    .font(DockWalkTheme.captionFont)
                    .foregroundStyle(DockWalkTheme.textSecondary)
            }
        }
        .listStyle(.insetGrouped)
    }
}
