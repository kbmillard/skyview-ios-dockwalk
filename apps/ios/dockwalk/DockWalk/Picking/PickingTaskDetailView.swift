import SwiftUI

struct PickingTaskDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(ScannerPreferencesStore.self) private var scannerPreferences
    @State private var viewModel: PickingTaskDetailViewModel
    @State private var showScanner = false
    @State private var selectedLine: PickLine?
    
    init(task: PickTask) {
        _viewModel = State(initialValue: PickingTaskDetailViewModel(task: task))
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DockWalkTheme.sectionSpacing) {
                    taskHeader
                    
                    if viewModel.task.status == .readyToPick || viewModel.task.status == .assigned {
                        startPickingSection
                    }
                    
                    if viewModel.task.status == .picking || viewModel.task.status == .picked {
                        progressSection
                    }
                    
                    pickLinesSection
                    
                    if viewModel.canCompletePick {
                        completeButton
                    }
                    
                    if viewModel.task.status == .picking {
                        blockButton
                    }
                }
                .padding(DockWalkTheme.screenPadding)
            }
            .background(DockWalkTheme.background)
            .navigationTitle("Pick Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                if scannerPreferences.isScannerActive && viewModel.task.status == .picking {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            showScanner = true
                        } label: {
                            Image(systemName: "barcode.viewfinder")
                                .font(.body.weight(.semibold))
                        }
                    }
                }
            }
            .sheet(isPresented: $showScanner) {
                BarcodeScannerSheet(title: "Scan item to pick") { result in
                    viewModel.handleScan(result)
                    showScanner = false
                }
            }
            .sheet(item: $selectedLine) { line in
                lineActionsSheet(for: line)
            }
            .alert("Complete Pick", isPresented: $viewModel.showConfirmComplete) {
                Button("Cancel", role: .cancel) { }
                Button("Complete") {
                    viewModel.completePick()
                    dismiss()
                }
            } message: {
                Text("Mark this pick task as complete? All picked items will be staged for loading.")
            }
            .alert("Block Task", isPresented: $viewModel.showBlockDialog) {
                TextField("Reason for blocking", text: $viewModel.blockReason)
                Button("Cancel", role: .cancel) { }
                Button("Block Task", role: .destructive) {
                    viewModel.blockTask()
                }
            } message: {
                Text("Why is this pick task blocked?")
            }
            .dismissScannerSheetWhenInactive(scannerPreferences, isPresented: $showScanner)
        }
    }
    
    private var taskHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.task.orderNumber)
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(DockWalkTheme.textPrimary)
                    
                    Text(viewModel.task.customer)
                        .font(.subheadline)
                        .foregroundStyle(DockWalkTheme.textSecondary)
                }
                
                Spacer()
                
                StatusChip(
                    label: viewModel.task.status.rawValue,
                    tone: statusTone(for: viewModel.task.status)
                )
            }
            
            Divider()
                .background(Color.gray.opacity(0.2))
            
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Shipment")
                        .font(.caption)
                        .foregroundStyle(DockWalkTheme.textSecondary)
                    Text(viewModel.task.shipmentId)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(DockWalkTheme.textPrimary)
                }
                
                if let dueDate = viewModel.task.dueDate {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Due")
                            .font(.caption)
                            .foregroundStyle(DockWalkTheme.textSecondary)
                        Text(dueDate.formatted(date: .abbreviated, time: .shortened))
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(DockWalkTheme.textPrimary)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Priority")
                        .font(.caption)
                        .foregroundStyle(DockWalkTheme.textSecondary)
                    Text(viewModel.task.priority.rawValue)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(priorityColor(for: viewModel.task.priority))
                }
            }
        }
        .padding(16)
        .background(DockWalkTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DockWalkTheme.cornerRadius))
    }
    
    private var startPickingSection: some View {
        VStack(spacing: 12) {
            if viewModel.task.status == .readyToPick {
                PrimaryActionButton(
                    title: "Assign to Me",
                    systemImage: "person.fill",
                    action: { viewModel.assignToMe() }
                )
            }
            
            if viewModel.canStartPicking {
                PrimaryActionButton(
                    title: "Start Picking",
                    systemImage: "hand.raised.fill",
                    action: { viewModel.startPicking() }
                )
            }
        }
    }
    
    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Progress")
                    .font(.headline)
                    .foregroundStyle(DockWalkTheme.textPrimary)
                
                Spacer()
                
                Text(viewModel.progressText)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(DockWalkTheme.textSecondary)
            }
            
            ProgressView(value: viewModel.progress)
                .tint(DockWalkTheme.success)
        }
        .padding(16)
        .background(DockWalkTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DockWalkTheme.cornerRadius))
    }
    
    private var pickLinesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pick Lines")
                .font(.headline)
                .foregroundStyle(DockWalkTheme.textPrimary)
            
            if !viewModel.pendingLines.isEmpty {
                linesGroup(title: "Pending", lines: viewModel.pendingLines, color: DockWalkTheme.textSecondary)
            }
            
            if !viewModel.pickingLines.isEmpty {
                linesGroup(title: "Picking", lines: viewModel.pickingLines, color: DockWalkTheme.warning)
            }
            
            if !viewModel.pickedLines.isEmpty {
                linesGroup(title: "Picked", lines: viewModel.pickedLines, color: DockWalkTheme.success)
            }
            
            if !viewModel.shortLines.isEmpty {
                linesGroup(title: "Short / Issues", lines: viewModel.shortLines, color: DockWalkTheme.danger)
            }
        }
    }
    
    private func linesGroup(title: String, lines: [PickLine], color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(color)
                
                Spacer()
                
                Text("\(lines.count)")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(DockWalkTheme.textSecondary)
            }
            
            ForEach(lines) { line in
                pickLineCard(line)
            }
        }
    }
    
    private func pickLineCard(_ line: PickLine) -> some View {
        Button {
            selectedLine = line
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(line.itemName)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(DockWalkTheme.textPrimary)
                        
                        Text("SKU \(line.sku) · From \(line.fromLocation)")
                            .font(.caption)
                            .foregroundStyle(DockWalkTheme.textSecondary)
                    }
                    
                    Spacer()
                    
                    if line.status == .pending || line.status == .picking {
                        HStack(spacing: 12) {
                            Button {
                                viewModel.decrementPicked(lineId: line.id)
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .font(.title3)
                                    .foregroundStyle(DockWalkTheme.textSecondary)
                            }
                            .disabled(line.quantityPicked == 0)
                            
                            Text("\(line.quantityPicked)/\(line.quantityOrdered)")
                                .font(.headline)
                                .foregroundStyle(DockWalkTheme.textPrimary)
                                .frame(minWidth: 50)
                            
                            Button {
                                viewModel.incrementPicked(lineId: line.id)
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title3)
                                    .foregroundStyle(DockWalkTheme.accent)
                            }
                            .disabled(line.quantityPicked >= line.quantityOrdered)
                        }
                    } else {
                        StatusChip(
                            label: line.status.rawValue,
                            tone: lineStatusTone(for: line.status)
                        )
                    }
                }
            }
            .padding(12)
            .background(DockWalkTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: DockWalkTheme.cornerRadius))
        }
        .buttonStyle(.plain)
    }
    
    private func lineActionsSheet(for line: PickLine) -> some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        viewModel.markLineShort(lineId: line.id)
                        selectedLine = nil
                    } label: {
                        Label("Mark as Short", systemImage: "exclamationmark.triangle")
                    }
                    
                    Button {
                        viewModel.markLineDamaged(lineId: line.id)
                        selectedLine = nil
                    } label: {
                        Label("Mark as Damaged", systemImage: "exclamationmark.octagon")
                    }
                    
                    Button {
                        viewModel.markLineNotFound(lineId: line.id)
                        selectedLine = nil
                    } label: {
                        Label("Mark as Not Found", systemImage: "questionmark.circle")
                    }
                }
            }
            .navigationTitle(line.itemName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        selectedLine = nil
                    }
                }
            }
        }
    }
    
    private var completeButton: some View {
        PrimaryActionButton(
            title: "Complete Pick",
            systemImage: "checkmark.circle.fill",
            action: { viewModel.showConfirmComplete = true }
        )
    }
    
    private var blockButton: some View {
        Button {
            viewModel.showBlockDialog = true
        } label: {
            HStack {
                Spacer()
                Label("Block Task", systemImage: "hand.raised.slash")
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
            }
            .frame(height: 56)
            .background(DockWalkTheme.danger)
            .clipShape(RoundedRectangle(cornerRadius: DockWalkTheme.cornerRadius))
        }
    }
    
    private func statusTone(for status: PickTaskStatus) -> StatusChip.Tone {
        switch status {
        case .readyToPick: return .neutral
        case .assigned: return .info
        case .picking: return .info
        case .picked: return .success
        case .staged: return .success
        case .blocked: return .warning
        case .complete: return .success
        case .cancelled: return .neutral
        }
    }
    
    private func lineStatusTone(for status: PickLineStatus) -> StatusChip.Tone {
        switch status {
        case .pending: return .neutral
        case .picking: return .info
        case .picked: return .success
        case .short, .damaged, .notFound: return .warning
        }
    }
    
    private func priorityColor(for priority: PickPriority) -> Color {
        switch priority {
        case .standard: return DockWalkTheme.textPrimary
        case .expedited: return DockWalkTheme.warning
        case .rush: return DockWalkTheme.danger
        }
    }
}

#Preview {
    PickingTaskDetailView(task: PickTask(
        id: "pick-1",
        shipmentId: "S-55120",
        orderNumber: "ORD-8821",
        customer: "Midwest Supply",
        status: .picking,
        priority: .standard,
        dueDate: Date().addingTimeInterval(86400),
        lines: [
            PickLine(
                id: "pl-1",
                taskId: "pick-1",
                sku: "BR-8821",
                upc: "00938122",
                partNumber: "AUTO-BR-01",
                itemName: "Brake Rotor Assembly",
                description: "Brake Rotor Assembly",
                fromLocation: "A-14",
                quantityOrdered: 12,
                quantityPicked: 8,
                status: .picking
            ),
        ],
        assignedTo: "Current User",
        createdAt: Date().addingTimeInterval(-7200),
        updatedAt: Date().addingTimeInterval(-300)
    ))
    .environment(ScannerPreferencesStore())
}
