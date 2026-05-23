import SwiftUI

/// Cases (CS) and eaches per case (EA/CS) with computed total — either field may be filled alone.
struct FormReceiveCasesEachesRow: View {
    @Binding var casesQty: String
    @Binding var eachesQty: String

    private var computedTotal: Int? {
        let cases = Int(casesQty.trimmingCharacters(in: .whitespaces)) ?? 0
        let eaches = Int(eachesQty.trimmingCharacters(in: .whitespaces)) ?? 0
        switch (cases > 0, eaches > 0) {
        case (true, true):
            return cases * eaches
        case (true, false):
            return cases
        case (false, true):
            return eaches
        case (false, false):
            return nil
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            FormValueRow(label: "CS", text: $casesQty, placeholder: "", keyboardType: .numberPad)
            FormValueRow(label: "EA/CS", text: $eachesQty, placeholder: "", keyboardType: .numberPad)

            if let summary = totalSummaryLine {
                Text(summary)
                    .font(DockWalkTheme.captionFont)
                    .foregroundStyle(DockWalkTheme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }

    private var totalSummaryLine: String? {
        let cases = Int(casesQty.trimmingCharacters(in: .whitespaces)) ?? 0
        let eaches = Int(eachesQty.trimmingCharacters(in: .whitespaces)) ?? 0
        switch (cases > 0, eaches > 0) {
        case (true, true):
            guard let total = computedTotal else { return nil }
            return "CS:\(cases) × EA:\(eaches) = \(total)"
        case (true, false):
            return "CS:\(cases)"
        case (false, true):
            return "EA:\(eaches)"
        case (false, false):
            return nil
        }
    }
}
