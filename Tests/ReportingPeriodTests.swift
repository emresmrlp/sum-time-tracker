import Foundation

@main
enum ReportingPeriodTests {
    static func main() {
        let formatter = ISO8601DateFormatter()
        func date(_ value: String) -> Date {
            guard let result = formatter.date(from: value) else {
                fatalError("Invalid test date: \(value)")
            }
            return result
        }

        var passed = 0
        func check(_ name: String, _ period: ReportingPeriod, at now: String,
                   previous: Bool = false, zone: String = "Europe/Istanbul",
                   start: String, end: String) {
            guard let interval = period.interval(containing: date(now), previous: previous,
                                                 timeZone: TimeZone(identifier: zone)!) else {
                fatalError("\(name): missing interval")
            }
            guard interval.start == date(start), interval.end == date(end) else {
                fatalError("\(name): expected \(start) – \(end), got \(interval)")
            }
            passed += 1
        }

        check("Midweek starts on Monday", .week, at: "2026-10-14T15:00:00+03:00",
              start: "2026-10-12T00:00:00+03:00", end: "2026-10-19T00:00:00+03:00")
        check("Sunday belongs to the existing week", .week, at: "2026-10-18T23:59:59+03:00",
              start: "2026-10-12T00:00:00+03:00", end: "2026-10-19T00:00:00+03:00")
        check("Monday midnight starts a new week", .week, at: "2026-10-19T00:00:00+03:00",
              start: "2026-10-19T00:00:00+03:00", end: "2026-10-26T00:00:00+03:00")
        check("Previous week is complete", .week, at: "2026-10-14T15:00:00+03:00", previous: true,
              start: "2026-10-05T00:00:00+03:00", end: "2026-10-12T00:00:00+03:00")
        check("Previous week at rollover", .week, at: "2026-10-19T00:00:00+03:00", previous: true,
              start: "2026-10-12T00:00:00+03:00", end: "2026-10-19T00:00:00+03:00")
        check("Week crosses a year boundary", .week, at: "2026-01-01T12:00:00+03:00",
              start: "2025-12-29T00:00:00+03:00", end: "2026-01-05T00:00:00+03:00")
        check("Previous week crosses a year boundary", .week, at: "2026-01-05T12:00:00+03:00", previous: true,
              start: "2025-12-29T00:00:00+03:00", end: "2026-01-05T00:00:00+03:00")

        check("31-day month", .month, at: "2026-10-14T15:00:00+03:00",
              start: "2026-10-01T00:00:00+03:00", end: "2026-11-01T00:00:00+03:00")
        check("30-day month", .month, at: "2026-04-30T23:59:59+03:00",
              start: "2026-04-01T00:00:00+03:00", end: "2026-05-01T00:00:00+03:00")
        check("28-day February", .month, at: "2026-02-28T23:59:59+03:00",
              start: "2026-02-01T00:00:00+03:00", end: "2026-03-01T00:00:00+03:00")
        check("29-day leap February", .month, at: "2028-02-29T23:59:59+03:00",
              start: "2028-02-01T00:00:00+03:00", end: "2028-03-01T00:00:00+03:00")
        check("First of month starts a new period", .month, at: "2026-11-01T00:00:00+03:00",
              start: "2026-11-01T00:00:00+03:00", end: "2026-12-01T00:00:00+03:00")
        check("Previous month is complete", .month, at: "2026-10-14T15:00:00+03:00", previous: true,
              start: "2026-09-01T00:00:00+03:00", end: "2026-10-01T00:00:00+03:00")
        check("March 31 compares with all of February", .month, at: "2026-03-31T15:00:00+03:00", previous: true,
              start: "2026-02-01T00:00:00+03:00", end: "2026-03-01T00:00:00+03:00")
        check("Previous leap month", .month, at: "2028-03-31T15:00:00+03:00", previous: true,
              start: "2028-02-01T00:00:00+03:00", end: "2028-03-01T00:00:00+03:00")
        check("January compares with December", .month, at: "2026-01-01T00:00:00+03:00", previous: true,
              start: "2025-12-01T00:00:00+03:00", end: "2026-01-01T00:00:00+03:00")

        check("Local Monday while UTC is still Sunday", .week, at: "2026-10-18T21:00:00Z",
              start: "2026-10-19T00:00:00+03:00", end: "2026-10-26T00:00:00+03:00")
        check("Local month rollover before UTC", .month, at: "2026-10-31T21:00:00Z",
              start: "2026-11-01T00:00:00+03:00", end: "2026-12-01T00:00:00+03:00")
        check("US week still starts Monday", .week, at: "2026-10-18T12:00:00-07:00", zone: "America/Los_Angeles",
              start: "2026-10-12T00:00:00-07:00", end: "2026-10-19T00:00:00-07:00")
        check("Spring DST week is 167 hours", .week, at: "2026-03-08T12:00:00-07:00", zone: "America/Los_Angeles",
              start: "2026-03-02T00:00:00-08:00", end: "2026-03-09T00:00:00-07:00")
        check("Autumn DST week is 169 hours", .week, at: "2026-11-01T12:00:00-08:00", zone: "America/Los_Angeles",
              start: "2026-10-26T00:00:00-07:00", end: "2026-11-02T00:00:00-08:00")
        check("Previous week preserves DST boundaries", .week, at: "2026-03-11T12:00:00-07:00", previous: true,
              zone: "America/Los_Angeles", start: "2026-03-02T00:00:00-08:00", end: "2026-03-09T00:00:00-07:00")
        check("Month preserves DST boundaries", .month, at: "2026-03-31T12:00:00-07:00", zone: "America/Los_Angeles",
              start: "2026-03-01T00:00:00-08:00", end: "2026-04-01T00:00:00-07:00")

        print("Passed \(passed) reporting period regression tests.")
    }
}
