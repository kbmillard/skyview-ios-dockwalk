import SwiftUI

/// Full-screen entry for confirming a single putaway step (scan + optional qty input).
struct PutawayConfirmView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(PutawaySessionStore.self) private var sessionStore

    let task: PutawayTaskItem
    let step: PutawayConfirmStep
    let initialScannedValue: String

    @State private var scannedValue: String = ""
    @State private var qtyText: String = ""
    @State private var validationMessage: String?

    init(task: PutawayTaskItem, step: PutawayConfirmStep, initialScannedValue: String = "") {
        self.task = task
        self.step = step
        self.initialScannedValue = initialScannedValue
    }

    private var expectedValue: String? {
        switch step {
        case .fromLocation: return task.fromLocationCode.isEmpty ? nil : task.fromLocationCode
        case .toLocation: return task.toLocationCode.isEmpty ? nil : task.toLocationCode
        case .sku: return task.sku.isEmpty ? nil : task.sku
        case .quantity: return nil
        }
    }

    private var matchesExpected: Bool {
        guard let expected = expectedValue else { return true }
        return scannedValue
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .compare(expected, options: .caseInsensitive) == .orderedSame
    }

    private var canSave: Bool {
        switch step {
        case .quantity:
            return (Double(qtyText.trimmingCharacters(in: .whitespaces)) ?? 0) > 0
        default:
            return !scannedValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    headerCard

                    if step == .quantity {
                        qtySection
                    } else {
                        scanResultSection
                    }

                    if let msg = validationMessage {
                        Text(msg)
                            .font(DockWalkTheme.captionFont)
                            .foregroundStyle(DockWalkTheme.warning)
                    }
                }
                .padding(DockWalkTheme.screenPadding)
            }
            .background(DockWalkTheme.background)
            .navigationTitle(step.scanTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(!canSave)
                }
            }
            .onAppear {
                scannedValue = initialScannedValue
                if step == .quantity {
                    qtyText = formatQuantity(task.quantity)
                }
            }
        }
    }

    private var headerCard: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 8) {
                Label("Task \(task.id)", systemImage: "shippingbox")
                    .font(DockWalkTheme.captionFont)
                    .foregroundStyle(DockWalkTheme.textSecondary)
                Text(task.sku)
                    .font(DockWalkTheme.headlineFont)
                Text(task.routeLabel)
                    .font(DockWalkTheme.captionFont)
                    .foregroundStyle(DockWalkTheme.textSecondary)
            }
        }
    }

    private var scanResultSection: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 10) {
                Text(step.displayName)
                    .font(DockWalkTheme.captionFont)
                    .foregroundStyle(DockWalkTheme.textSecondary)
                TextField("Scanned value", text: $scannedValue)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .font(DockWalkTheme.bodyFont)
                if let expected = expectedValue {
                    HStack(spacing: 6) {
                        Image(systemName: matchesExpected ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                            .foregroundStyle(matchesExpected ? DockWalkTheme.accent : DockWalkTheme.warning)
                        Text("Expected: \(expected)")
                            .font(DockWalkTheme.captionFont)
                            .foregroundStyle(DockWalkTheme.textSecondary)
                    }
                }
            }
        }
    }

    private var qtySection: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("Quantity (\(task.uom))")
                    .font(DockWalkTheme.captionFont)
                    .foregroundStyle(DockWalkTheme.textSecondary)
                TextField("", text: $qtyText)
                    .keyboardType(.decimalPad)
                    .font(DockWalkTheme.bodyFont)
                Text("Expected: \(formatQuantity(task.quantity)) \(task.uom)")
                    .font(DockWalkTheme.captionFont)
                    .foregroundStyle(DockWalkTheme.textSecondary)
            }
        }
    }

    private func save() {
        let trimmedScan = scannedValue.trimmingCharacters(in: .whitespacesAndNewlines)
        switch step {
        case .quantity:
            guard let qty = Double(qtyText.trimmingCharacters(in: .whitespaces)), qty > 0 else {
                validationMessage = "Enter a quantity greater than zero."
                return
            }
            var draft = PutawayConfirmDraft.empty(taskId: task.id, step: .quantity)
            draft.confirmedQty = qty
            draft.scannedValue = "\(formatQuantity(qty)) \(task.uom)"
            sessionStore.appendDraft(draft)
            _ = sessionStore.saveDraft(draft)
        default:
            guard !trimmedScan.isEmpty else {
                validationMessage = "Scan or enter a value."
                return
            }
            var draft = PutawayConfirmDraft.fromScan(taskId: task.id, step: step, value: trimmedScan)
            sessionStore.appendDraft(draft)
            _ = sessionStore.saveDraft(draft)
            _ = draft
        }
        dismiss()
    }

    private func formatQuantity(_ value: Double) -> String {
        value == floor(value) ? String(Int(value)) : String(value)
    }
}
