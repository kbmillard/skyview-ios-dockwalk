import SwiftUI

struct PickingTasksView: View {
    @Environment(ScannerPreferencesStore.self) private var scannerPreferences
    @State private var viewModel = PickingTasksViewModel()
    @State private var selectedTask: PickTask?
    @State private var showScanner = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: DockWalkTheme.sectionSpacing) {
                searchField
                    .padding(.horizontal, DockWalkTheme.screenPadding)
                
                if viewModel.readyToPickTasks.isEmpty && viewModel.assignedTasks.isEmpty && viewModel.pickingTasks.isEmpty {
                    emptyState
                } else {
                    taskSections
                }
            }
            .padding(.vertical, DockWalkTheme.screenPadding)
        }
        .background(DockWalkTheme.background)
        .navigationTitle("Picking")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            if scannerPreferences.isScannerActive {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showScanner = true
                    } label: {
                        Image(systemName: "barcode.viewfinder")
                            .font(.body.weight(.semibold))
                    }
                }
            }
        }
        .sheet(item: $selectedTask) { task in
            PickingTaskDetailView(task: task)
        }
        .sheet(isPresented: $showScanner) {
            BarcodeScannerSheet(title: "Scan pick item") { result in
                viewModel.searchQuery = result.value
                showScanner = false
            }
        }
        .dismissScannerSheetWhenInactive(scannerPreferences, isPresented: $showScanner)
    }
    
    private var searchField: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(DockWalkTheme.textSecondary)
            TextField("Search order, customer, or shipment", text: $viewModel.searchQuery)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            if !viewModel.searchQuery.isEmpty {
                Button {
                    viewModel.searchQuery = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(DockWalkTheme.textSecondary)
                }
            }
        }
        .padding(14)
        .background(DockWalkTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DockWalkTheme.cornerRadius))
    }
    
    private var taskSections: some View {
        VStack(spacing: DockWalkTheme.sectionSpacing) {
            if !viewModel.readyToPickTasks.isEmpty {
                taskSection(title: "Ready to Pick", tasks: viewModel.readyToPickTasks)
            }
            
            if !viewModel.assignedTasks.isEmpty {
                taskSection(title: "Assigned to Me", tasks: viewModel.assignedTasks)
            }
            
            if !viewModel.pickingTasks.isEmpty {
                taskSection(title: "Picking", tasks: viewModel.pickingTasks)
            }
            
            if !viewModel.pickedTasks.isEmpty {
                taskSection(title: "Picked", tasks: viewModel.pickedTasks)
            }
            
            if !viewModel.blockedTasks.isEmpty {
                taskSection(title: "Blocked", tasks: viewModel.blockedTasks)
            }
        }
    }
    
    private func taskSection(title: String, tasks: [PickTask]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(DockWalkTheme.textPrimary)
                Spacer()
                Text("\(tasks.count)")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(DockWalkTheme.textSecondary)
            }
            .padding(.horizontal, DockWalkTheme.screenPadding)
            
            VStack(spacing: 8) {
                ForEach(tasks) { task in
                    pickTaskCard(task)
                }
            }
            .padding(.horizontal, DockWalkTheme.screenPadding)
        }
    }
    
    private func pickTaskCard(_ task: PickTask) -> some View {
        Button {
            selectedTask = task
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(task.orderNumber)
                            .font(.headline)
                            .foregroundStyle(DockWalkTheme.textPrimary)
                        
                        Text(task.customer)
                            .font(.subheadline)
                            .foregroundStyle(DockWalkTheme.textSecondary)
                    }
                    
                    Spacer()
                    
                    StatusChip(
                        label: task.priority.rawValue,
                        tone: task.priority == .rush ? .warning : .neutral
                    )
                }
                
                Divider()
                    .background(Color.gray.opacity(0.2))
                
                HStack(spacing: 16) {
                    Label("\(task.lines.count) lines", systemImage: "list.bullet")
                        .font(.caption)
                        .foregroundStyle(DockWalkTheme.textSecondary)
                    
                    if let dueDate = task.dueDate {
                        Label(dueDate.formatted(date: .abbreviated, time: .shortened), systemImage: "clock")
                            .font(.caption)
                            .foregroundStyle(DockWalkTheme.textSecondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(DockWalkTheme.textSecondary)
                }
            }
            .padding(16)
            .background(DockWalkTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: DockWalkTheme.cornerRadius))
        }
        .buttonStyle(.plain)
    }
    
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.system(size: 48))
                .foregroundStyle(DockWalkTheme.textSecondary)
            
            Text("No picking tasks")
                .font(.headline)
                .foregroundStyle(DockWalkTheme.textPrimary)
            
            Text("Picking tasks will appear here when available")
                .font(.subheadline)
                .foregroundStyle(DockWalkTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(DockWalkTheme.screenPadding * 2)
    }
}

#Preview {
    PickingTasksView()
        .environment(ScannerPreferencesStore())
}
