import Foundation
import Observation

@Observable
final class PickingTaskDetailViewModel {
    var task: PickTask
    var scanInput = ""
    var showConfirmComplete = false
    var showBlockDialog = false
    var blockReason = ""
    
    init(task: PickTask) {
        self.task = task
    }
    
    var progress: Double {
        let totalOrdered = task.lines.reduce(0) { $0 + $1.quantityOrdered }
        let totalPicked = task.lines.reduce(0) { $0 + $1.quantityPicked }
        guard totalOrdered > 0 else { return 0 }
        return Double(totalPicked) / Double(totalOrdered)
    }
    
    var progressText: String {
        let totalOrdered = task.lines.reduce(0) { $0 + $1.quantityOrdered }
        let totalPicked = task.lines.reduce(0) { $0 + $1.quantityPicked }
        return "\(totalPicked) of \(totalOrdered) picked"
    }
    
    var pendingLines: [PickLine] {
        task.lines.filter { $0.status == .pending }
    }
    
    var pickingLines: [PickLine] {
        task.lines.filter { $0.status == .picking }
    }
    
    var pickedLines: [PickLine] {
        task.lines.filter { $0.status == .picked }
    }
    
    var shortLines: [PickLine] {
        task.lines.filter { $0.status == .short }
    }
    
    var canStartPicking: Bool {
        task.status == .readyToPick || task.status == .assigned
    }
    
    var canCompletePick: Bool {
        task.status == .picking && pendingLines.isEmpty && pickingLines.isEmpty
    }
    
    func assignToMe() {
        task.assignedTo = "Current User"
        task.status = .assigned
        task.updatedAt = Date()
    }
    
    func startPicking() {
        guard canStartPicking else { return }
        task.status = .picking
        task.updatedAt = Date()
    }
    
    func handleScan(_ result: ScanResult) {
        // Find matching line by UPC
        guard let lineIndex = task.lines.firstIndex(where: { line in
            line.upc == result.value && (line.status == .pending || line.status == .picking)
        }) else {
            // No match - could show error or allow manual search
            return
        }
        
        // Update line status
        task.lines[lineIndex].status = .picking
        task.lines[lineIndex].scannedAt = Date()
        task.updatedAt = Date()
    }
    
    func incrementPicked(lineId: String) {
        guard let index = task.lines.firstIndex(where: { $0.id == lineId }) else { return }
        let line = task.lines[index]
        
        if line.quantityPicked < line.quantityOrdered {
            task.lines[index].quantityPicked += 1
            
            // If fully picked, mark as picked
            if task.lines[index].quantityPicked == line.quantityOrdered {
                task.lines[index].status = .picked
            } else {
                task.lines[index].status = .picking
            }
            
            task.updatedAt = Date()
        }
    }
    
    func decrementPicked(lineId: String) {
        guard let index = task.lines.firstIndex(where: { $0.id == lineId }) else { return }
        
        if task.lines[index].quantityPicked > 0 {
            task.lines[index].quantityPicked -= 1
            
            // Update status
            if task.lines[index].quantityPicked == 0 {
                task.lines[index].status = .pending
            } else {
                task.lines[index].status = .picking
            }
            
            task.updatedAt = Date()
        }
    }
    
    func markLineShort(lineId: String) {
        guard let index = task.lines.firstIndex(where: { $0.id == lineId }) else { return }
        task.lines[index].status = .short
        task.updatedAt = Date()
    }
    
    func markLineDamaged(lineId: String) {
        guard let index = task.lines.firstIndex(where: { $0.id == lineId }) else { return }
        task.lines[index].status = .damaged
        task.updatedAt = Date()
    }
    
    func markLineNotFound(lineId: String) {
        guard let index = task.lines.firstIndex(where: { $0.id == lineId }) else { return }
        task.lines[index].status = .notFound
        task.updatedAt = Date()
    }
    
    func completePick() {
        guard canCompletePick else { return }
        task.status = .picked
        task.updatedAt = Date()
        showConfirmComplete = false
    }
    
    func blockTask() {
        guard !blockReason.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        task.status = .blocked
        task.updatedAt = Date()
        showBlockDialog = false
        blockReason = ""
    }
}
