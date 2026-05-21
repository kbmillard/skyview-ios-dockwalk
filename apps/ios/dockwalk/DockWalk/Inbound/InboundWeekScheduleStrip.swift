import SwiftUI

struct InboundWeekScheduleStrip: View {
    let weekDays: [Date]
    let selectedDay: Date
    let scheduledCount: (Date) -> Int
    let onSelectDay: (Date) -> Void

    private let calendar = Calendar.current

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Week schedule")
                .font(DockWalkTheme.captionFont)
                .foregroundStyle(DockWalkTheme.textSecondary)
                .padding(.horizontal, DockWalkTheme.screenPadding)

            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(weekDays, id: \.timeIntervalSince1970) { day in
                            dayChip(for: day)
                                .id(day.timeIntervalSince1970)
                        }
                    }
                    .padding(.horizontal, DockWalkTheme.screenPadding)
                }
                .onAppear {
                    scrollToSelectedDay(proxy: proxy)
                }
                .onChange(of: selectedDay.timeIntervalSince1970) { _, _ in
                    scrollToSelectedDay(proxy: proxy)
                }
            }
        }
        .padding(.vertical, 8)
        .background(DockWalkTheme.cardBackground.opacity(0.6))
    }

    private func dayChip(for day: Date) -> some View {
        let isSelected = InboundWeekSchedule.isSameCalendarDay(day, selectedDay, calendar: calendar)
        let isToday = calendar.isDateInToday(day)
        let count = scheduledCount(day)

        return Button {
            onSelectDay(InboundWeekSchedule.startOfDay(day, calendar: calendar))
        } label: {
            VStack(spacing: 4) {
                Text(InboundWeekSchedule.shortWeekdayLabel(for: day, calendar: calendar))
                    .font(.system(size: 11, weight: .medium))
                Text(InboundWeekSchedule.dayOfMonthLabel(for: day, calendar: calendar))
                    .font(.system(size: 17, weight: .semibold))
                Text("\(count)")
                    .font(.system(size: 12, weight: .medium))
            }
            .frame(width: 52)
            .padding(.vertical, 8)
            .foregroundStyle(isSelected ? .white : DockWalkTheme.textPrimary)
            .background(isSelected ? DockWalkTheme.accent : DockWalkTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(
                        isToday && !isSelected ? DockWalkTheme.accent : Color.clear,
                        lineWidth: 2
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(InboundWeekSchedule.shortWeekdayLabel(for: day)), \(count) scheduled")
    }

    private func scrollToSelectedDay(proxy: ScrollViewProxy) {
        let target = selectedDay.timeIntervalSince1970
        DispatchQueue.main.async {
            withAnimation(.easeInOut(duration: 0.25)) {
                proxy.scrollTo(target, anchor: .center)
            }
        }
    }
}
