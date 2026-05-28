import SwiftUI

struct ActivityView: View {
    @Environment(AppEnvironment.self) private var environment
    @Environment(OfflineSyncStore.self) private var syncStore
    @State private var viewModel: ActivityViewModel?
    @State private var selectedEvent: AuditEventItem?

    var body: some View {
        Group {
            if let viewModel, viewModel.loadPhase == .loaded {
                activityList(viewModel)
            } else if let viewModel, !viewModel.pendingEntries.isEmpty, viewModel.loadPhase.isFailure {
                activityList(viewModel)
            } else if let viewModel {
                LoadStateView(phase: viewModel.loadPhase) {
                    Task { await viewModel.refresh() }
                }
            } else {
                ProgressView()
            }
        }
        .navigationTitle("Activity")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            await viewModel?.refresh()
        }
        .sheet(item: $selectedEvent) { event in
            AuditEventDetailSheet(event: event)
        }
        .onAppear {
            ensureViewModel()
        }
        .task(id: environment.configRevision) {
            ensureViewModel()
            await viewModel?.refresh()
        }
        .onChange(of: syncStore.queuedActions) { _, _ in
            viewModel?.bind(syncStore: syncStore)
        }
    }

    private func ensureViewModel() {
        if viewModel == nil {
            let vm = ActivityViewModel(environment: environment, syncStore: syncStore)
            vm.bind(syncStore: syncStore)
            viewModel = vm
        } else {
            viewModel?.bind(syncStore: syncStore)
        }
    }

    @ViewBuilder
    private func activityList(_ viewModel: ActivityViewModel) -> some View {
        List {
            if let mode = viewModel.dataMode {
                Section {
                    StatusChip(
                        label: mode == "live" ? "Live trail" : "Offline preview",
                        tone: mode == "live" ? .success : .neutral
                    )
                }
            }

            if !viewModel.pendingEntries.isEmpty {
                Section("Pending sync") {
                    ForEach(viewModel.pendingEntries) { action in
                        pendingRow(action)
                    }
                }
            }

            Section("Server activity") {
                ForEach(viewModel.events) { event in
                    Button {
                        selectedEvent = event
                    } label: {
                        auditRow(event)
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

                if viewModel.events.isEmpty {
                    Text("No server events yet.")
                        .foregroundStyle(DockWalkTheme.textSecondary)
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private func auditRow(_ event: AuditEventItem) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(event.action.capitalized)
                    .font(DockWalkTheme.headlineFont)
                Spacer()
                if let date = event.createdAt {
                    Text(date.formatted(date: .abbreviated, time: .shortened))
                        .font(DockWalkTheme.captionFont)
                        .foregroundStyle(DockWalkTheme.textSecondary)
                }
            }

            if let barcode = event.primaryIdentifier {
                Text(barcode)
                    .font(.system(.body, design: .monospaced).weight(.medium))
            }

            Text(event.entityType.replacingOccurrences(of: "_", with: " "))
                .font(DockWalkTheme.captionFont)
                .foregroundStyle(DockWalkTheme.textSecondary)

            if let summary = event.payloadSummary {
                Text(summary)
                    .font(DockWalkTheme.captionFont)
                    .foregroundStyle(DockWalkTheme.textSecondary)
            }
        }
        .padding(.vertical, 4)
    }

    private func pendingRow(_ action: QueuedSyncAction) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(action.kindDisplayName)
                    .font(.caption.weight(.semibold))
                Spacer()
                Text(action.createdAt.formatted(date: .omitted, time: .shortened))
                    .font(DockWalkTheme.captionFont)
                    .foregroundStyle(DockWalkTheme.textSecondary)
            }
            if let barcode = action.primaryBarcode {
                Text(barcode)
                    .font(.system(.body, design: .monospaced).weight(.medium))
            }
            Text(action.summary)
                .font(DockWalkTheme.captionFont)
            if let error = action.lastError {
                Text(error)
                    .font(DockWalkTheme.captionFont)
                    .foregroundStyle(DockWalkTheme.danger)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct AuditEventDetailSheet: View {
    let event: AuditEventItem
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Event") {
                    LabeledContent("Action", value: event.action)
                    LabeledContent("Entity", value: event.entityType)
                    if let barcode = event.primaryIdentifier {
                        LabeledContent("Identifier", value: barcode)
                            .font(.system(.body, design: .monospaced))
                    }
                    if let entityId = event.entityId {
                        LabeledContent("Entity ID", value: entityId)
                            .font(.system(.body, design: .monospaced))
                    }
                    if let date = event.createdAt {
                        LabeledContent("When", value: date.formatted(date: .abbreviated, time: .standard))
                    }
                }
                if !event.detailLines.isEmpty {
                    Section("Details") {
                        ForEach(event.detailLines, id: \.self) { line in
                            Text(line)
                                .font(DockWalkTheme.captionFont)
                        }
                    }
                }
            }
            .navigationTitle("Activity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

private extension LoadPhase {
    var isFailure: Bool {
        if case .error = self { return true }
        return false
    }
}

#Preview {
    NavigationStack {
        ActivityView()
            .environment(AppEnvironment.shared)
            .environment(OfflineSyncStore.shared)
    }
}
