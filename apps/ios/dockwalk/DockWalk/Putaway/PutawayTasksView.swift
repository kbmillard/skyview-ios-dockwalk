import SwiftUI

struct PutawayTasksView: View {
    @Environment(AppEnvironment.self) private var environment
    @Environment(OfflineSyncStore.self) private var syncStore
    @Environment(DemoOperationalDataStore.self) private var demoOperationalData
    @State private var viewModel: PutawayTasksViewModel?

    private let inboundShipmentId: String?
    private let navigationTitle: String

    init(inboundShipmentId: String? = nil, isOperationalTabRoot: Bool = false) {
        self.inboundShipmentId = inboundShipmentId
        if inboundShipmentId != nil {
            self.navigationTitle = "Putaway for shipment"
        } else if isOperationalTabRoot {
            self.navigationTitle = "Putaway"
        } else {
            self.navigationTitle = "Putaway tasks"
        }
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
        .navigationBarTitleDisplayMode(inboundShipmentId == nil ? .large : .inline)
        .refreshable {
            await viewModel?.refresh()
        }
        .onAppear {
            if viewModel == nil {
                viewModel = PutawayTasksViewModel(
                    environment: environment,
                    inboundShipmentId: inboundShipmentId
                )
            }
        }
        .task(id: "\(environment.configRevision)-\(demoOperationalData.revision)") {
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
                        label: putawayModeLabel(mode),
                        tone: mode == "live" ? .success : (mode == "foundation" ? .warning : .neutral)
                    )
                    if mode == "foundation-demo" {
                        Text("Demo mode — putaway list is empty until you receive on a load. Live API task seeds are hidden.")
                            .font(DockWalkTheme.captionFont)
                            .foregroundStyle(DockWalkTheme.textSecondary)
                    }
                    if mode == "foundation" {
                        Text("Showing dev-seed preview data — Railway API host is unreachable. Task writes will fail until the API is restored.")
                            .font(DockWalkTheme.captionFont)
                            .foregroundStyle(DockWalkTheme.warning)
                    }
                    Text("Tap a task to assign, start, block, or complete. Actions sync online; transport failures queue for More → Sync or Debug replay.")
                        .font(DockWalkTheme.captionFont)
                        .foregroundStyle(DockWalkTheme.textSecondary)
                    if syncStore.pendingTaskActionCount > 0 {
                        Text("\(syncStore.pendingTaskActionCount) putaway action(s) queued for sync.")
                            .font(DockWalkTheme.captionFont)
                            .foregroundStyle(DockWalkTheme.warning)
                    }
                }
            }

            Section {
                statusFilterChips(viewModel)
            }

            if !viewModel.tasks.isEmpty {
                Section {
                    PutawayQueueSnapshot(
                        cards: viewModel.tasks,
                        shipmentLabel: inboundShipmentId
                    )
                    .listRowInsets(EdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 12))
                    .listRowBackground(Color.clear)
                }
            }

            Section {
                ForEach(viewModel.tasks) { task in
                    NavigationLink {
                        PutawayTaskHubView(initialTask: task) {
                            Task { await viewModel.refresh() }
                        }
                    } label: {
                        putawayRow(task)
                    }
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
                Text(task.upc)
                    .font(.system(.headline, design: .monospaced))
                Spacer()
                StatusChip(label: task.status.displayName, tone: task.status.chipTone)
            }
            if let sku = task.secondarySKULabel {
                Text(sku)
                    .font(DockWalkTheme.captionFont)
                    .foregroundStyle(DockWalkTheme.textSecondary)
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
        case "blocked": return .warning
        case "cancelled": return .neutral
        default: return .neutral
        }
    }

    private func putawayModeLabel(_ mode: String) -> String {
        switch mode {
        case "live": return "Live tasks"
        case "foundation-demo": return "Demo (no tasks)"
        case "foundation": return "Offline preview"
        default: return "Stub API"
        }
    }
}
