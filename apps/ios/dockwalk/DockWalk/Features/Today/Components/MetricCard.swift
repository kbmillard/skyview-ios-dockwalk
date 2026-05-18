import SwiftUI

/// Pattern B: Metric Card for dashboard stats
/// Used for: Dock doors, Outbound, Inventory
struct MetricCard: View {
    let metrics: [Metric]
    let caption: String?
    let action: (() -> Void)?
    
    struct Metric {
        let label: String
        let value: String
        let color: Color?
        
        init(label: String, value: String, color: Color? = nil) {
            self.label = label
            self.value = value
            self.color = color
        }
    }
    
    init(
        metrics: [Metric],
        caption: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.metrics = metrics
        self.caption = caption
        self.action = action
    }
    
    var body: some View {
        Group {
            if let action = action {
                Button(action: action) {
                    cardContent
                }
                .buttonStyle(.plain)
            } else {
                cardContent
            }
        }
    }
    
    private var cardContent: some View {
        VStack(alignment: .leading, spacing: Tokens.Space.base) {
            // Metrics row
            HStack(spacing: 0) {
                ForEach(Array(metrics.enumerated()), id: \.offset) { index, metric in
                    metricBlock(metric)
                    
                    if index < metrics.count - 1 {
                        Divider()
                            .frame(width: 0.5, height: 40)
                            .background(Tokens.Color.Divider.hairline)
                            .padding(.horizontal, Tokens.Space.base)
                    }
                }
                
                if action != nil {
                    Spacer(minLength: Tokens.Space.base)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Tokens.Color.Ink.tertiary)
                }
            }
            
            // Optional caption
            if let caption = caption {
                Text(caption)
                    .font(Tokens.Font.bodySecondary)
                    .foregroundStyle(Tokens.Color.Ink.secondary)
            }
        }
        .padding(Tokens.Space.lg - 4) // 20pt
        .frame(minHeight: action != nil ? Tokens.TapTarget.minimum : nil)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Tokens.Color.Surface.card)
        .clipShape(RoundedRectangle(cornerRadius: Tokens.Radius.card))
    }
    
    private func metricBlock(_ metric: Metric) -> some View {
        VStack(alignment: .leading, spacing: Tokens.Space.xs) {
            Text(metric.label.uppercased())
                .font(Tokens.Font.bodyMeta)
                .foregroundStyle(Tokens.Color.Ink.secondary)
            Text(metric.value)
                .font(Tokens.Font.displayMetric)
                .foregroundStyle(metric.color ?? Tokens.Color.Ink.primary)
        }
    }
}
