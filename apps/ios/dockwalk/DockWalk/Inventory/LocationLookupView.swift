import SwiftUI

struct LocationLookupView: View {
    @State private var locationQuery = ""
    @State private var locationResults: [InventoryItem] = []
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DockWalkTheme.sectionSpacing) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Find items by location code (bin, aisle, zone).")
                        .font(DockWalkTheme.captionFont)
                        .foregroundStyle(DockWalkTheme.textSecondary)
                    
                    HStack {
                        Image(systemName: "mappin.and.ellipse")
                            .foregroundStyle(DockWalkTheme.textSecondary)
                        TextField("Enter location code", text: $locationQuery)
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()
                    }
                    .padding(14)
                    .background(DockWalkTheme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: DockWalkTheme.cornerRadius))
                }
                
                if !locationQuery.isEmpty {
                    resultsSection
                }
            }
            .padding(DockWalkTheme.screenPadding)
        }
        .background(DockWalkTheme.background)
        .navigationTitle("Location Lookup")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: locationQuery) { _, newValue in
            performLookup(newValue)
        }
    }
    
    private var resultsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(locationResults.isEmpty ? "No items found" : "Items at this location")
                .font(DockWalkTheme.headlineFont)
            
            if locationResults.isEmpty {
                SectionCard {
                    VStack(spacing: 8) {
                        Image(systemName: "mappin.slash")
                            .font(.largeTitle)
                            .foregroundStyle(DockWalkTheme.textSecondary)
                        Text("No items found at '\(locationQuery)'")
                            .font(DockWalkTheme.bodyFont)
                            .foregroundStyle(DockWalkTheme.textSecondary)
                        Text("Try a different location code or use the main inventory search.")
                            .font(DockWalkTheme.captionFont)
                            .foregroundStyle(DockWalkTheme.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                }
            } else {
                ForEach(locationResults) { item in
                    SectionCard {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(item.sku)
                                    .font(.system(.body, design: .monospaced).weight(.semibold))
                                Spacer()
                                if item.reserved > 0 {
                                    StatusChip(label: "Reserved", tone: .warning)
                                }
                            }
                            Text(item.description)
                                .font(DockWalkTheme.bodyFont)
                            Divider()
                            HStack(spacing: 20) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("On hand")
                                        .font(DockWalkTheme.captionFont)
                                        .foregroundStyle(DockWalkTheme.textSecondary)
                                    Text("\(item.onHand)")
                                        .font(.system(.body, design: .rounded).weight(.semibold))
                                }
                                if item.reserved > 0 {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Available")
                                            .font(DockWalkTheme.captionFont)
                                            .foregroundStyle(DockWalkTheme.textSecondary)
                                        Text("\(item.onHand - item.reserved)")
                                            .font(.system(.body, design: .rounded).weight(.semibold))
                                            .foregroundStyle(DockWalkTheme.success)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func performLookup(_ query: String) {
        let mockItems = [
            InventoryItem(
                id: "inv-1",
                sku: "SKU-44102",
                upc: nil,
                partDescription: "BEV-CS-01",
                itemName: "Cases — beverage",
                description: "Cases — beverage",
                quantity: 480,
                location: "A-12-03",
                status: .reserved,
                onHand: 480,
                reserved: 48
            ),
            InventoryItem(
                id: "inv-2",
                sku: "SKU-99201",
                upc: nil,
                partDescription: "CHEM-DR-01",
                itemName: "Drums — chemical",
                description: "Drums — chemical",
                quantity: 36,
                location: "C-04-01",
                status: .available,
                onHand: 36,
                reserved: 0
            ),
            InventoryItem(
                id: "inv-3",
                sku: "SKU-22018",
                upc: nil,
                partDescription: "RET-PAL-01",
                itemName: "Pallet — mixed retail",
                description: "Pallet — mixed retail",
                quantity: 120,
                location: "B-08-02",
                status: .reserved,
                onHand: 120,
                reserved: 24
            ),
        ]
        
        let normalizedQuery = query.lowercased()
        locationResults = mockItems.filter { item in
            item.location.lowercased().contains(normalizedQuery)
        }
    }
}

#Preview {
    NavigationStack {
        LocationLookupView()
    }
}
