import Foundation

enum ReportRange: String, CaseIterable {
    case day
    case week
    case month
    case all
}

struct ReportBucket: Identifiable {
    var id: Date { start }
    let start: Date
    let end: Date
    let duration: TimeInterval
}

/// Calendar-based report calculations, independent of the UI and timer lifecycle.
enum ReportAnalytics {
    private static func calendar(in timeZone: TimeZone) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        calendar.firstWeekday = 2
        calendar.minimumDaysInFirstWeek = 4
        return calendar
    }

    /// Produce a consistent, as-of-now view of saved and currently running sessions.
    /// Timestamps are authoritative; legacy cached durations can be stale.
    static func snapshot(_ sessions: [TimeSession], at now: Date) -> [TimeSession] {
        guard now.timeIntervalSinceReferenceDate.isFinite else { return [] }
        return sessions.compactMap { session in
            guard valid(session) else { return nil }
            let end = min(session.endTime, now)
            guard end > session.startTime else { return nil }
            return TimeSession(id: session.id, startTime: session.startTime, endTime: end,
                               duration: end.timeIntervalSince(session.startTime))
        }.sorted { $0.startTime < $1.startTime }
    }

    static func interval(for range: ReportRange, containing date: Date,
                         sessions: [TimeSession], now: Date = Date(),
                         timeZone: TimeZone = .autoupdatingCurrent) -> DateInterval {
        let calendar = calendar(in: timeZone)
        switch range {
        case .day:
            return calendar.dateInterval(of: .day, for: date) ?? DateInterval(start: date, duration: 0)
        case .week:
            return ReportingPeriod.week.interval(containing: date, timeZone: timeZone)
                ?? DateInterval(start: date, duration: 0)
        case .month:
            return ReportingPeriod.month.interval(containing: date, timeZone: timeZone)
                ?? DateInterval(start: date, duration: 0)
        case .all:
            let today = calendar.startOfDay(for: now)
            let firstStart = snapshot(sessions, at: now).first?.startTime ?? today
            let start = calendar.startOfDay(for: min(firstStart, today))
            let end = calendar.date(byAdding: .day, value: 1, to: today) ?? now
            return DateInterval(start: start, end: end)
        }
    }

    /// Intersections are half-open: a session ending at midnight belongs only to
    /// the preceding day. Session IDs survive clipping for stable SwiftUI rows.
    static func segments(in interval: DateInterval, sessions: [TimeSession]) -> [TimeSession] {
        guard valid(interval) else { return [] }
        return sessions.compactMap { session in
            guard valid(session) else { return nil }
            let start = max(session.startTime, interval.start)
            let end = min(session.endTime, interval.end)
            guard end > start else { return nil }
            return TimeSession(id: session.id, startTime: start, endTime: end,
                               duration: end.timeIntervalSince(start))
        }.sorted { $0.startTime < $1.startTime }
    }

    static func total(in interval: DateInterval, sessions: [TimeSession]) -> TimeInterval {
        segments(in: interval, sessions: sessions).reduce(0) { $0 + $1.duration }
    }

    /// Day → hours, week → days, month → Monday-based weeks, all → months.
    /// Boundary buckets are clipped, so their sum always equals the period total.
    static func buckets(for range: ReportRange, in interval: DateInterval,
                        sessions: [TimeSession],
                        timeZone: TimeZone = .autoupdatingCurrent) -> [ReportBucket] {
        guard valid(interval) else { return [] }
        let calendar = calendar(in: timeZone)
        let component: Calendar.Component
        switch range {
        case .day: component = .hour
        case .week: component = .day
        case .month: component = .weekOfYear
        case .all: component = .month
        }

        let clipped = segments(in: interval, sessions: sessions)
        var result: [ReportBucket] = []
        var start = interval.start
        while start < interval.end {
            guard let calendarInterval = calendar.dateInterval(of: component, for: start) else { break }
            let end = min(calendarInterval.end, interval.end)
            guard end > start else { break }
            let bucketInterval = DateInterval(start: start, end: end)
            result.append(ReportBucket(start: start, end: end,
                                       duration: total(in: bucketInterval, sessions: clipped)))
            start = end
        }
        return result
    }

    private static func valid(_ session: TimeSession) -> Bool {
        session.startTime.timeIntervalSinceReferenceDate.isFinite
            && session.endTime.timeIntervalSinceReferenceDate.isFinite
            && session.endTime > session.startTime
    }

    private static func valid(_ interval: DateInterval) -> Bool {
        interval.start.timeIntervalSinceReferenceDate.isFinite
            && interval.end.timeIntervalSinceReferenceDate.isFinite
            && interval.end > interval.start
    }
}
