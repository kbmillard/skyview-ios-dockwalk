import SwiftUI

struct ActivityView: View {
    @Environment(AppEnvironment.self) private var environment
    @State private var viewModel: ActivityViewModel?
    @State private var selectedEvent: AuditEventItem?

    var body: some View {
        Group {
            if let viewModel, viewModel.loadPhase == .loaded {
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
            if viewModel == nil {
                viewModel = ActivityViewModel(environment: environment)
            }
        }
        .task(id: environment.configRevision) {
            if viewModel == nil {
                viewModel = ActivityViewModel(environment: environment)
            }
            await viewModel?.refresh()
        }
    }

    @ViewBuilder
    private func activityList(_ viewModel: ActivityViewModel) -> some View {
        List {
            if let mode = viewModel.dataMode {
                Section {
                    StatusChip(
                        label: mode == "live" ? "Live audit trail" : "Stub API",
                        tone: mode == "live" ? .success : .neutral
                    )
                }
            }

            Section {
                ForEach(viewModel.events) { event in
                    Button {
                        selectedEvent = event
                    } label: {
                        activityRow(event)
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

    private func activityRow(_ event: AuditEventItem) -> some View {
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
            Text(event.entityType.replacingOccurrences(of: "_", with: " "))
                .font(DockWalkTheme.captionFont)
                .foregroundStyle(DockWalkTheme.textSecondary)
            if let summary = event.payloadSummary {
                Text(summary)
                    .font(DockWalkTheme.captionFont)
                    .foregroundStyle(DockWalkTheme.textSecondary)
            }
            if let entityId = event.entityId {
                Text(entityId)
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(DockWalkTheme.textSecondary)
                    .lineLimit(1)
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
            .navigationTitle("Audit event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        ActivityView()
            .environment(AppEnvironment.shared)
    }
}
