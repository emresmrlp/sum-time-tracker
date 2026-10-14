import Foundation
import Combine
import AppKit

class TimeManager: ObservableObject {
    static let shared = TimeManager()
    
    @Published var isTracking = false
    @Published var currentSessionDuration: TimeInterval = 0
    @Published var sessions: [TimeSession] = []
    @Published var lastRefreshDate: Date = Date()
    
    private var timer: Timer?
    private var midnightTimer: Timer?
    private var periodicTimer: Timer?
    private var currentStartTime: Date?
    private var currentSessionID = UUID()
    private var currentDayStart: Date = Calendar.autoupdatingCurrent.startOfDay(for: Date())
    private var cancellables = Set<AnyCancellable>()
    
    private var calendar: Calendar {
        Calendar.autoupdatingCurrent
    }
    
    init() {
        currentDayStart = calendar.startOfDay(for: Date())
        loadSessions()
        scheduleMidnightTimer()
        setupPeriodicCheck()
        setupNotificationObservers()
    }
    
    deinit {
        timer?.invalidate()
        midnightTimer?.invalidate()
        periodicTimer?.invalidate()
    }
    
    private func setupNotificationObservers() {
        NotificationCenter.default.publisher(for: .NSCalendarDayChanged)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.checkDayChange(forceRefresh: true)
            }.store(in: &cancellables)
            
        NotificationCenter.default.publisher(for: NSNotification.Name.NSSystemClockDidChange)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.checkDayChange(forceRefresh: true)
            }.store(in: &cancellables)
            
        NotificationCenter.default.publisher(for: NSNotification.Name.NSSystemTimeZoneDidChange)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.checkDayChange(forceRefresh: true)
            }.store(in: &cancellables)
            
        NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.didWakeNotification)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.checkDayChange(forceRefresh: true)
            }.store(in: &cancellables)
    }
    
    private func scheduleMidnightTimer() {
        midnightTimer?.invalidate()
        midnightTimer = nil
        let now = Date()
        guard let nextMidnight = calendar.nextDate(after: now, matching: DateComponents(hour: 0, minute: 0, second: 0), matchingPolicy: .nextTime) else { return }
        
        let interval = max(1.0, nextMidnight.timeIntervalSince(now) + 0.2)
        let timer = Timer(timeInterval: interval, repeats: false) { [weak self] _ in
            self?.checkDayChange(forceRefresh: true)
        }
        midnightTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }
    
    private func setupPeriodicCheck() {
        periodicTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            self?.checkDayChange()
        }
        if let periodicTimer = periodicTimer {
            RunLoop.main.add(periodicTimer, forMode: .common)
        }
    }
    
    func checkDayChange(forceRefresh: Bool = false) {
        let now = Date()
        let todayStart = calendar.startOfDay(for: now)
        let dayChanged = (todayStart != currentDayStart)
        
        if dayChanged || forceRefresh {
            currentDayStart = todayStart
            scheduleMidnightTimer()
            
            // If tracking was active across midnight, split the session so yesterday gets completed session
            if dayChanged && isTracking, let startTime = currentStartTime, startTime < todayStart {
                let yesterdaySession = TimeSession(startTime: startTime, endTime: todayStart, duration: todayStart.timeIntervalSince(startTime))
                sessions.append(yesterdaySession)
                saveSessions()
                currentStartTime = todayStart
                currentSessionID = UUID()
                currentSessionDuration = now.timeIntervalSince(todayStart)
            }
            
            lastRefreshDate = now
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
    }
    
    func toggleTracking() {
        if isTracking {
            stopTracking()
        } else {
            startTracking()
        }
    }
    
    func startTracking() {
        guard !isTracking else { return }
        checkDayChange()
        isTracking = true
        currentStartTime = Date()
        currentSessionID = UUID()
        currentSessionDuration = 0
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.checkDayChange()
            guard let startTime = self.currentStartTime else { return }
            self.currentSessionDuration = Date().timeIntervalSince(startTime)
        }
        RunLoop.main.add(timer!, forMode: .common)
        lastRefreshDate = Date()
    }
    
    func stopTracking() {
        guard isTracking, let startTime = currentStartTime else { return }
        isTracking = false
        timer?.invalidate()
        timer = nil
        
        let endTime = Date()
        let splitSessions = splitSessionIfNeeded(startTime: startTime, endTime: endTime)
        sessions.append(contentsOf: splitSessions)
        saveSessions()
        
        currentSessionDuration = 0
        currentStartTime = nil
        checkDayChange(forceRefresh: true)
    }
    
    private func splitSessionIfNeeded(startTime: Date, endTime: Date) -> [TimeSession] {
        guard endTime > startTime else { return [] }
        var result: [TimeSession] = []
        var currentStart = startTime
        
        while true {
            let dayStart = calendar.startOfDay(for: currentStart)
            guard let nextDayStart = calendar.date(byAdding: .day, value: 1, to: dayStart) else {
                result.append(TimeSession(startTime: currentStart, endTime: endTime, duration: endTime.timeIntervalSince(currentStart)))
                break
            }
            
            if endTime <= nextDayStart {
                result.append(TimeSession(startTime: currentStart, endTime: endTime, duration: endTime.timeIntervalSince(currentStart)))
                break
            } else {
                result.append(TimeSession(startTime: currentStart, endTime: nextDayStart, duration: nextDayStart.timeIntervalSince(currentStart)))
                currentStart = nextDayStart
            }
        }
        return result
    }
    
    // MARK: - Overlap Duration Calculation
    func duration(from intervalStart: Date, to intervalEnd: Date) -> TimeInterval {
        guard intervalEnd > intervalStart else { return 0 }
        
        var total: TimeInterval = 0
        
        for session in sessions {
            let sStart = session.startTime
            let sEnd = session.endTime
            let overlapStart = max(sStart, intervalStart)
            let overlapEnd = min(sEnd, intervalEnd)
            if overlapEnd > overlapStart {
                total += overlapEnd.timeIntervalSince(overlapStart)
            }
        }
        
        if isTracking, let currentStart = currentStartTime {
            let now = Date()
            let overlapStart = max(currentStart, intervalStart)
            let overlapEnd = min(now, intervalEnd)
            if overlapEnd > overlapStart {
                total += overlapEnd.timeIntervalSince(overlapStart)
            }
        }
        
        return total
    }
    
    // MARK: - Current Periods
    func getTodayTotal() -> TimeInterval {
        let now = Date()
        let todayStart = calendar.startOfDay(for: now)
        guard let tomorrowStart = calendar.date(byAdding: .day, value: 1, to: todayStart) else { return 0 }
        return duration(from: todayStart, to: min(now, tomorrowStart))
    }
    
    func getWeeklyTotal() -> TimeInterval {
        return total(for: .week)
    }
    
    func getMonthlyTotal() -> TimeInterval {
        return total(for: .month)
    }
    
    // MARK: - Past Periods (for comparison)
    func getYesterdayTotal() -> TimeInterval {
        let now = Date()
        let todayStart = calendar.startOfDay(for: now)
        guard let yesterdayStart = calendar.date(byAdding: .day, value: -1, to: todayStart) else { return 0 }
        return duration(from: yesterdayStart, to: todayStart)
    }
    
    func getLastWeekTotal() -> TimeInterval {
        return total(for: .week, previous: true)
    }
    
    func getLastMonthTotal() -> TimeInterval {
        return total(for: .month, previous: true)
    }

    private func total(for period: ReportingPeriod, previous: Bool = false) -> TimeInterval {
        let now = Date()
        guard let interval = period.interval(containing: now, previous: previous) else { return 0 }
        return duration(from: interval.start, to: min(now, interval.end))
    }
    
    // MARK: - Storage & Reports
    func reportSessions(at now: Date = Date()) -> [TimeSession] {
        var result = sessions
        if isTracking, let start = currentStartTime, now > start {
            result.append(TimeSession(id: currentSessionID, startTime: start, endTime: now,
                                      duration: now.timeIntervalSince(start)))
        }
        return ReportAnalytics.snapshot(result, at: now)
    }

    private var dataFolderURL: URL {
        return SettingsManager.shared.dataFolderURL
    }
    
    private var dataFileURL: URL {
        return dataFolderURL.appendingPathComponent("data.json")
    }
    
    private func saveSessions() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        if let encoded = try? encoder.encode(sessions) {
            try? encoded.write(to: dataFileURL)
        }
    }
    
    func reloadSessionsAfterSetup() {
        guard !isTracking else { return }
        sessions = []
        loadSessions()
        checkDayChange(forceRefresh: true)
    }

    private func loadSessions() {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        if let savedData = try? Data(contentsOf: dataFileURL),
           let decoded = try? decoder.decode([TimeSession].self, from: savedData) {
            sessions = decoded
        } else {
            // Fallback for old default encoding if iso8601 fails
            if let savedData = try? Data(contentsOf: dataFileURL),
               let decoded = try? JSONDecoder().decode([TimeSession].self, from: savedData) {
                sessions = decoded
            }
        }
    }
    
    enum ReportError: Error {
        case alreadyExists
    }
    
    func generateReport() throws {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm"
        let dateString = formatter.string(from: Date())
        let reportFileName = "Report_\(dateString).txt"
        let reportURL = dataFolderURL.appendingPathComponent(reportFileName)
        
        if FileManager.default.fileExists(atPath: reportURL.path) {
            throw ReportError.alreadyExists
        }
        
        var reportContent = """
        ========================================
                 SUM TIME TRACKER REPORT        
        ========================================
        Generated at: \(Date().description(with: Locale.current))
        
        [ TODAY ]
        Current: \(formatTimeInterval(getTodayTotal()))
        Yesterday: \(formatTimeInterval(getYesterdayTotal()))
        
        [ THIS WEEK ]
        Current: \(formatTimeInterval(getWeeklyTotal()))
        Last Week: \(formatTimeInterval(getLastWeekTotal()))
        
        [ THIS MONTH ]
        Current: \(formatTimeInterval(getMonthlyTotal()))
        Last Month: \(formatTimeInterval(getLastMonthTotal()))
        ========================================
        
        [ RECENT SESSIONS (LAST 7 DAYS) ]

        """
        
        guard let oneWeekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) else { return }
        let recentSessions = sessions.filter { $0.startTime >= oneWeekAgo }.sorted(by: { $0.startTime > $1.startTime })
        
        let sessionFormatter = DateFormatter()
        sessionFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        if recentSessions.isEmpty {
            reportContent += "No recent sessions.\n"
        } else {
            for session in recentSessions {
                let startStr = sessionFormatter.string(from: session.startTime)
                let endStr = sessionFormatter.string(from: session.endTime)
                let durStr = formatTimeInterval(session.duration)
                reportContent += "- \(startStr) to \(endStr) | Duration: \(durStr)\n"
            }
        }
        reportContent += "========================================\n"
        
        try? reportContent.write(to: reportURL, atomically: true, encoding: .utf8)
    }
    
    private func formatTimeInterval(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = Int(interval) / 60 % 60
        return String(format: "%dh %02dm", hours, minutes)
    }
}
