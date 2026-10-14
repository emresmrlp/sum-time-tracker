import Foundation

enum ReportingPeriod {
    case week
    case month

    func interval(containing date: Date, previous: Bool = false,
                  timeZone: TimeZone = .autoupdatingCurrent) -> DateInterval? {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        // Reporting weeks always run Monday–Sunday, regardless of locale settings.
        calendar.firstWeekday = 2
        calendar.minimumDaysInFirstWeek = 4

        let component: Calendar.Component = self == .week ? .weekOfYear : .month
        guard let current = calendar.dateInterval(of: component, for: date) else { return nil }
        guard previous else { return current }

        // Move from the period's start so short months cannot shift the boundary.
        guard let previousStart = calendar.date(byAdding: component, value: -1, to: current.start) else {
            return nil
        }
        return calendar.dateInterval(of: component, for: previousStart)
    }
}
