import Foundation

enum InboundWeekSchedule {
    static func startOfDay(_ date: Date, calendar: Calendar = .current) -> Date {
        calendar.startOfDay(for: date)
    }

    static func weekDays(containing date: Date, calendar: Calendar = .current) -> [Date] {
        let start = calendar.dateInterval(of: .weekOfYear, for: date)?.start
            ?? startOfDay(date, calendar: calendar)
        return (0..<7).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: start)
        }
    }

    static func isSameCalendarDay(_ lhs: Date, _ rhs: Date, calendar: Calendar = .current) -> Bool {
        calendar.isDate(lhs, inSameDayAs: rhs)
    }

    static func shortWeekdayLabel(for date: Date, calendar: Calendar = .current) -> String {
        date.formatted(.dateTime.weekday(.abbreviated))
    }

    static func dayOfMonthLabel(for date: Date, calendar: Calendar = .current) -> String {
        date.formatted(.dateTime.day())
    }

    /// Demo queue anchor: the Friday one week after the upcoming Friday (e.g. May 29 when today is May 20).
    static func demoInboundQueueDay(calendar: Calendar = .current, reference: Date = Date()) -> Date {
        let today = startOfDay(reference, calendar: calendar)
        let fridayWeekday = 6
        let weekday = calendar.component(.weekday, from: today)
        var daysUntilFriday = (fridayWeekday - weekday + 7) % 7
        if daysUntilFriday == 0 {
            daysUntilFriday = 7
        }
        guard let upcomingFriday = calendar.date(byAdding: .day, value: daysUntilFriday, to: today),
              let queueFriday = calendar.date(byAdding: .weekOfYear, value: 1, to: upcomingFriday)
        else {
            return today
        }
        return startOfDay(queueFriday, calendar: calendar)
    }
}
