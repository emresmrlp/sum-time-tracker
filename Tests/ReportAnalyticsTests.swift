import Foundation

@main
enum ReportAnalyticsTests {
    static func main() {
        let formatter = ISO8601DateFormatter()
        let istanbul = TimeZone(identifier: "Europe/Istanbul")!
        let losAngeles = TimeZone(identifier: "America/Los_Angeles")!
        var passed = 0

        func date(_ value: String) -> Date {
            guard let result = formatter.date(from: value) else {
                fatalError("Invalid test date: \(value)")
            }
            return result
        }

        func check(_ name: String, _ condition: @autoclosure () -> Bool) {
            guard condition() else { fatalError("Failed: \(name)") }
            passed += 1
        }

        func session(_ start: String, _ end: String) -> TimeSession {
            let startDate = date(start)
            let endDate = date(end)
            return TimeSession(startTime: startDate, endTime: endDate,
                               duration: endDate.timeIntervalSince(startDate))
        }

        func interval(_ start: String, _ end: String) -> DateInterval {
            DateInterval(start: date(start), end: date(end))
        }

        func report(_ range: ReportRange, at value: String, sessions: [TimeSession] = [],
                    zone: TimeZone? = nil) -> DateInterval {
            let now = date(value)
            return ReportAnalytics.interval(for: range, containing: now, sessions: sessions,
                                            now: now, timeZone: zone ?? istanbul)
        }

        func checkCoverage(_ name: String, _ buckets: [ReportBucket],
                           _ expected: DateInterval, duration: TimeInterval) {
            check("\(name): first boundary", buckets.first?.start == expected.start)
            check("\(name): last boundary", buckets.last?.end == expected.end)
            check("\(name): contiguous positive buckets", zip(buckets, buckets.dropFirst()).allSatisfy { pair in
                pair.0.end == pair.1.start && pair.0.end > pair.0.start
            } && buckets.last.map { $0.end > $0.start } == true)
            check("\(name): total preserved", buckets.reduce(0) { $0 + $1.duration } == duration)
        }

        let today = report(.day, at: "2026-10-14T12:00:00+03:00")
        check("Day covers local midnight to midnight",
              today == interval("2026-10-14T00:00:00+03:00", "2026-10-15T00:00:00+03:00"))
        let emptyHours = ReportAnalytics.buckets(for: .day, in: today, sessions: [], timeZone: istanbul)
        check("Empty day has all 24 hours", emptyHours.count == 24)
        check("Empty day has zero total", emptyHours.allSatisfy { $0.duration == 0 })

        let overnight = session("2026-10-13T23:30:00+03:00", "2026-10-14T01:30:00+03:00")
        let previousDay = report(.day, at: "2026-10-13T12:00:00+03:00")
        check("Overnight session allocates first day", ReportAnalytics.total(in: previousDay, sessions: [overnight]) == 1800)
        check("Overnight session allocates second day", ReportAnalytics.total(in: today, sessions: [overnight]) == 5400)
        let clipped = ReportAnalytics.segments(in: today, sessions: [overnight])
        check("Clipping preserves session identity", clipped.first?.id == overnight.id)
        check("Clipping adjusts timestamps", clipped.first?.startTime == today.start && clipped.first?.endTime == overnight.endTime)
        check("Clipping recalculates duration", clipped.first?.duration == 5400)
        let overnightHours = ReportAnalytics.buckets(for: .day, in: today, sessions: [overnight], timeZone: istanbul)
        check("Hourly buckets split partial work", overnightHours[0].duration == 3600 && overnightHours[1].duration == 1800)
        checkCoverage("Overnight hourly report", overnightHours, today, duration: 5400)

        let endsAtMidnight = session("2026-10-13T23:00:00+03:00", "2026-10-14T00:00:00+03:00")
        let startsAtMidnight = session("2026-10-14T00:00:00+03:00", "2026-10-14T01:00:00+03:00")
        let adjacent = [endsAtMidnight, startsAtMidnight]
        check("Midnight endpoints are never counted twice", ReportAnalytics.total(in: today, sessions: adjacent) == 3600
              && ReportAnalytics.total(in: previousDay, sessions: adjacent) == 3600)
        check("Touching endpoint does not add empty segment", ReportAnalytics.segments(in: today, sessions: [endsAtMidnight]).isEmpty)

        let now = date("2026-10-19T00:30:00+03:00")
        let running = session("2026-10-18T23:30:00+03:00", "2026-10-20T12:00:00+03:00")
        let live = ReportAnalytics.snapshot([running], at: now)
        let newWeek = report(.week, at: "2026-10-19T00:30:00+03:00")
        let oldWeek = report(.week, at: "2026-10-18T12:00:00+03:00")
        check("Live snapshot clips unelapsed time", live.first?.endTime == now && live.first?.duration == 3600)
        check("Live snapshot keeps stable identity", live.first?.id == running.id)
        check("Sunday live work belongs to old week", ReportAnalytics.total(in: oldWeek, sessions: live) == 1800)
        check("Monday live work belongs to new week", ReportAnalytics.total(in: newWeek, sessions: live) == 1800)
        let weekBuckets = ReportAnalytics.buckets(for: .week, in: newWeek, sessions: live, timeZone: istanbul)
        check("Week has Monday to Sunday buckets", weekBuckets.count == 7 && weekBuckets.first?.duration == 1800
              && weekBuckets.dropFirst().allSatisfy { $0.duration == 0 })
        checkCoverage("Weekly report", weekBuckets, newWeek, duration: 1800)

        var staleDuration = startsAtMidnight
        staleDuration.duration = -99
        let reversed = session("2026-10-14T11:00:00+03:00", "2026-10-14T10:00:00+03:00")
        let emptySession = session("2026-10-14T11:00:00+03:00", "2026-10-14T11:00:00+03:00")
        let future = session("2026-10-20T09:00:00+03:00", "2026-10-20T10:00:00+03:00")
        let invalidDate = TimeSession(startTime: Date(timeIntervalSinceReferenceDate: .nan), endTime: now, duration: 100)
        let sanitized = ReportAnalytics.snapshot([reversed, emptySession, future, invalidDate, staleDuration], at: now)
        check("Snapshot excludes invalid, empty and future entries", sanitized.count == 1)
        check("Snapshot ignores stale cached duration", sanitized.first?.duration == 3600)
        check("Segments independently reject malformed intervals", ReportAnalytics.segments(in: today, sessions: [reversed, emptySession, invalidDate]).isEmpty)
        check("Invalid cutoff does not create report data", ReportAnalytics.snapshot([running], at: Date(timeIntervalSinceReferenceDate: .nan)).isEmpty)
        let zeroInterval = DateInterval(start: now, duration: 0)
        check("Empty interval produces no buckets", ReportAnalytics.buckets(for: .day, in: zeroInterval, sessions: live).isEmpty)
        check("Empty interval produces no duration", ReportAnalytics.total(in: zeroInterval, sessions: live) == 0)

        let october = report(.month, at: "2026-10-14T12:00:00+03:00")
        let fullOctober = session("2026-09-30T23:00:00+03:00", "2026-11-01T01:00:00+03:00")
        let octoberWeeks = ReportAnalytics.buckets(for: .month, in: october, sessions: [fullOctober], timeZone: istanbul)
        check("October has five calendar week buckets", octoberWeeks.count == 5)
        check("First monthly week excludes September", octoberWeeks.first?.duration == 4 * 24 * 3600)
        check("Last monthly week excludes November", octoberWeeks.last?.duration == 6 * 24 * 3600)
        check("Interior weeks begin Monday", octoberWeeks[1].start == date("2026-10-05T00:00:00+03:00"))
        checkCoverage("Monthly partial weeks", octoberWeeks, october, duration: 31 * 24 * 3600)
        let fourWeekMonth = report(.month, at: "2021-02-14T12:00:00+03:00")
        check("Month beginning Monday can have four weeks", ReportAnalytics.buckets(for: .month, in: fourWeekMonth, sessions: [], timeZone: istanbul).count == 4)
        let sixWeekMonth = report(.month, at: "2026-08-14T12:00:00+03:00")
        check("Month can span six calendar weeks", ReportAnalytics.buckets(for: .month, in: sixWeekMonth, sessions: [], timeZone: istanbul).count == 6)

        let leapFebruary = report(.month, at: "2028-02-29T12:00:00+03:00")
        let leapSession = session("2028-02-01T00:00:00+03:00", "2028-03-01T00:00:00+03:00")
        let leapWeeks = ReportAnalytics.buckets(for: .month, in: leapFebruary, sessions: [leapSession], timeZone: istanbul)
        checkCoverage("Leap month", leapWeeks, leapFebruary, duration: 29 * 24 * 3600)

        let spring = report(.day, at: "2026-03-08T12:00:00-07:00", zone: losAngeles)
        let springSession = TimeSession(startTime: spring.start, endTime: spring.end, duration: spring.duration)
        let springHours = ReportAnalytics.buckets(for: .day, in: spring, sessions: [springSession], timeZone: losAngeles)
        check("Spring daylight-saving day has 23 real hours", springHours.count == 23)
        checkCoverage("Spring daylight-saving day", springHours, spring, duration: 23 * 3600)
        let autumn = report(.day, at: "2026-11-01T12:00:00-08:00", zone: losAngeles)
        let autumnSession = TimeSession(startTime: autumn.start, endTime: autumn.end, duration: autumn.duration)
        let autumnHours = ReportAnalytics.buckets(for: .day, in: autumn, sessions: [autumnSession], timeZone: losAngeles)
        check("Autumn daylight-saving day has 25 real hours", autumnHours.count == 25)
        check("Repeated clock hour has distinct bucket IDs", Set(autumnHours.map(\.id)).count == 25)
        checkCoverage("Autumn daylight-saving day", autumnHours, autumn, duration: 25 * 3600)
        let springWeek = report(.week, at: "2026-03-08T12:00:00-07:00", zone: losAngeles)
        let springWeekSession = TimeSession(startTime: springWeek.start, endTime: springWeek.end, duration: springWeek.duration)
        let springDays = ReportAnalytics.buckets(for: .week, in: springWeek, sessions: [springWeekSession], timeZone: losAngeles)
        check("DST week still has seven calendar days", springDays.count == 7)
        check("DST Sunday uses elapsed 23 hours", springDays.last?.duration == 23 * 3600)
        checkCoverage("Spring daylight-saving week", springDays, springWeek, duration: 167 * 3600)

        let emptyAll = report(.all, at: "2026-10-14T12:00:00+03:00")
        check("Empty history covers today", emptyAll == today)
        check("Empty history has one zero monthly bucket", ReportAnalytics.buckets(for: .all, in: emptyAll, sessions: [], timeZone: istanbul).count == 1)
        let earliest = session("2018-01-15T09:00:00+03:00", "2018-01-15T10:00:00+03:00")
        let latest = session("2026-10-14T10:00:00+03:00", "2026-10-14T11:00:00+03:00")
        let history = [latest, future, earliest]
        let all = report(.all, at: "2026-10-14T12:00:00+03:00", sessions: history)
        check("All history starts with earliest session day", all.start == date("2018-01-15T00:00:00+03:00"))
        check("Future history does not extend all-time interval", all.end == today.end)
        let months = ReportAnalytics.buckets(for: .all, in: all, sessions: history, timeZone: istanbul)
        check("All-time monthly history is not truncated", months.count == 106)
        check("Empty months remain visible", months[1].duration == 0)
        check("Boundary months keep their totals", months.first?.duration == 3600 && months.last?.duration == 3600)
        checkCoverage("All-time report", months, all, duration: 7200)
        check("Future-only history falls back to today", report(.all, at: "2026-10-14T12:00:00+03:00", sessions: [future]) == today)

        let oldJSON = """
        [{"id":"ED807EA1-314D-4F1A-B95F-F04AD044F14F","startTime":"2026-10-14T06:00:00Z","endTime":"2026-10-14T07:00:00Z","duration":3600}]
        """.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let oldSessions = try! decoder.decode([TimeSession].self, from: oldJSON)
        check("Existing saved session schema stays compatible", oldSessions.count == 1 && oldSessions[0].duration == 3600)

        print("Passed \(passed) report analytics regression tests.")
    }
}
