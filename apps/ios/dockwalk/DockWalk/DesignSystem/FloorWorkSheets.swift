import SwiftUI

// MARK: - Exception marking

struct ExceptionMarkingSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Tagging this load as flagged will route it to **Needs Review** for office sign-off.")
                        .font(DockWalkTheme.bodyFont)
                        .foregroundStyle(DockWalkTheme.textSecondary)
                        .padding(.bottom, 4)

                    exceptionOption(
                        title: "Damage",
                        detail: "Visible damage to packaging, pallet, or product",
                        systemImage: "exclamationmark.triangle.fill",
                        tone: .danger
                    )
                    exceptionOption(
                        title: "Overage",
                        detail: "Received more than BOL quantity",
                        systemImage: "plus.circle",
                        tone: .warning
                    )
                    exceptionOption(
                        title: "Shortage",
                        detail: "Received less than BOL quantity",
                        systemImage: "minus.circle",
                        tone: .warning
                    )
                    exceptionOption(
                        title: "Unknown SKU",
                        detail: "Item not in catalog · requires office review",
                        systemImage: "magnifyingglass",
                        tone: .neutral
                    )
                    exceptionOption(
                        title: "Missing paperwork",
                        detail: "BOL, packing list, or invoice not provided",
                        systemImage: "doc",
                        tone: .neutral
                    )
                }
                .padding(DockWalkTheme.screenPadding)
            }
            .background(DockWalkTheme.background)
            .navigationTitle("Mark exception")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func exceptionOption(
        title: String,
        detail: String,
        systemImage: String,
        tone: StatusChip.Tone
    ) -> some View {
        Button {
            dismiss()
        } label: {
            SectionCard {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: systemImage)
                        .font(.title3)
                        .foregroundStyle(toneColor(tone))
                        .frame(width: 32)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(DockWalkTheme.headlineFont)
                            .foregroundStyle(DockWalkTheme.textPrimary)
                        Text(detail)
                            .font(DockWalkTheme.captionFont)
                            .foregroundStyle(DockWalkTheme.textSecondary)
                    }
                    Spacer()
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func toneColor(_ tone: StatusChip.Tone) -> Color {
        switch tone {
        case .neutral: return DockWalkTheme.textSecondary
        case .info: return DockWalkTheme.accent
        case .success: return DockWalkTheme.success
        case .warning: return DockWalkTheme.warning
        case .danger: return DockWalkTheme.danger
        }
    }
}

// MARK: - Scan confirmation

struct ScanConfirmSheet: View {
    @Environment(\.dismiss) private var dismiss
    let payload: ScanConfirmPayload

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(payload.context)
                        .font(DockWalkTheme.captionFont)
                        .foregroundStyle(DockWalkTheme.textSecondary)

                    SectionCard {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "checkmark")
                                .font(.title3.weight(.bold))
                                .foregroundStyle(DockWalkTheme.success)
                                .frame(width: 36, height: 36)
                                .background(DockWalkTheme.success.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 10))

                            VStack(alignment: .leading, spacing: 4) {
                                Text(payload.itemName)
                                    .font(DockWalkTheme.headlineFont)
                                Text("SKU \(payload.sku) · UPC \(payload.upc)")
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundStyle(DockWalkTheme.textSecondary)
                                Text("Vendor **\(payload.vendor)** · Destination **\(payload.destination)**")
                                    .font(DockWalkTheme.captionFont)
                                    .foregroundStyle(DockWalkTheme.textSecondary)
                            }

                            Spacer(minLength: 0)

                            Text("\(payload.confidence)%")
                                .font(.system(.caption2, design: .monospaced).weight(.bold))
                                .foregroundStyle(DockWalkTheme.success)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(DockWalkTheme.success.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                    }

                    HStack(spacing: 12) {
                        Button("Reject") { dismiss() }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(DockWalkTheme.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 14))

                        Button("Accept & continue") { dismiss() }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .foregroundStyle(.white)
                            .background(Color(red: 0.04, green: 0.08, blue: 0.16))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .font(.system(.body, design: .rounded).weight(.semibold))
                }
                .padding(DockWalkTheme.screenPadding)
            }
            .background(DockWalkTheme.background)
            .navigationTitle("Scan confirmed")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Dock door selector

struct DockDoorSelectorSheet: View {
    @Environment(\.dismiss) private var dismiss
    let loadId: String
    @State private var selectedDoorId = "D-10"

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 4)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Pick an available door for **\(loadId)**. Busy doors are shown but disabled.")
                        .font(DockWalkTheme.bodyFont)
                        .foregroundStyle(DockWalkTheme.textSecondary)

                    LazyVGrid(columns: columns, spacing: 6) {
                        ForEach(MockWarehouseFloor.dockDoors) { door in
                            doorCell(door)
                        }
                    }

                    HStack(spacing: 12) {
                        Button("Cancel") { dismiss() }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(DockWalkTheme.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 14))

                        Button("Assign \(selectedDoorId)") { dismiss() }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .foregroundStyle(.white)
                            .background(Color(red: 0.04, green: 0.08, blue: 0.16))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .font(.system(.body, design: .rounded).weight(.semibold))
                }
                .padding(DockWalkTheme.screenPadding)
            }
            .background(DockWalkTheme.background)
            .navigationTitle("Assign dock door")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func doorCell(_ door: MockWarehouseFloor.DockDoorOption) -> some View {
        Button {
            guard !door.isBusy else { return }
            selectedDoorId = door.id
        } label: {
            VStack(spacing: 2) {
                Text(door.label)
                    .font(.system(.caption, design: .monospaced).weight(.semibold))
                Text(door.status)
                    .font(.system(size: 9, design: .monospaced))
                    .textCase(.uppercase)
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 52)
            .foregroundStyle(selectedDoorId == door.id ? .white : DockWalkTheme.textPrimary)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(selectedDoorId == door.id
                          ? Color(red: 0.04, green: 0.08, blue: 0.16)
                          : DockWalkTheme.cardBackground)
            )
            .opacity(door.isBusy ? 0.45 : 1)
        }
        .buttonStyle(.plain)
        .disabled(door.isBusy)
    }
}
