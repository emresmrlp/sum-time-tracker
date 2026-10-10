import Foundation
import Combine
import AppKit

struct TimeSession: Codable, Identifiable {
    var id = UUID()
    var startTime: Date
    var endTime: Date
    var duration: TimeInterval
}

class TimeManager: ObservableObject {
    static let shared = TimeManager()
    
    @Published var isTracking = false
    @Published var currentSessionDuration: TimeInterval = 0
    @Published var sessions: [TimeSession] = []
    
    private var timer: Timer?
    private var currentStartTime: Date?
    
    init() {
        loadSessions()
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
        isTracking = true
        currentStartTime = Date()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, let startTime = self.currentStartTime else { return }
            self.currentSessionDuration = Date().timeIntervalSince(startTime)
        }
        RunLoop.main.add(timer!, forMode: .common)
    }
    
    func stopTracking() {
        guard isTracking, let startTime = currentStartTime else { return }
        isTracking = false
        timer?.invalidate()
        timer = nil
        
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        
        let newSession = TimeSession(startTime: startTime, endTime: endTime, duration: duration)
        sessions.append(newSession)
        saveSessions()
        
        currentSessionDuration = 0
        currentStartTime = nil
    }
    
    // MARK: - Current Periods
    func getTodayTotal() -> TimeInterval {
        let calendar = Calendar.current
        return sessions.filter { calendar.isDateInToday($0.startTime) }
            .reduce(0) { $0 + $1.duration } + (isTracking ? currentSessionDuration : 0)
    }
    
    func getWeeklyTotal() -> TimeInterval {
        let calendar = Calendar.current
        guard let oneWeekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) else { return 0 }
        return sessions.filter { $0.startTime >= oneWeekAgo }
            .reduce(0) { $0 + $1.duration } + (isTracking ? currentSessionDuration : 0)
    }
    
    func getMonthlyTotal() -> TimeInterval {
        let calendar = Calendar.current
        guard let oneMonthAgo = calendar.date(byAdding: .month, value: -1, to: Date()) else { return 0 }
        return sessions.filter { $0.startTime >= oneMonthAgo }
            .reduce(0) { $0 + $1.duration } + (isTracking ? currentSessionDuration : 0)
    }
    
    // MARK: - Past Periods (for comparison)
    func getYesterdayTotal() -> TimeInterval {
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: Date())
        guard let yesterdayStart = calendar.date(byAdding: .day, value: -1, to: todayStart) else { return 0 }
        
        return sessions.filter { $0.startTime >= yesterdayStart && $0.startTime < todayStart }
            .reduce(0) { $0 + $1.duration }
    }
    
    func getLastWeekTotal() -> TimeInterval {
        let calendar = Calendar.current
        let today = Date()
        guard let oneWeekAgo = calendar.date(byAdding: .day, value: -7, to: today),
              let twoWeeksAgo = calendar.date(byAdding: .day, value: -14, to: today) else { return 0 }
        
        return sessions.filter { $0.startTime >= twoWeeksAgo && $0.startTime < oneWeekAgo }
            .reduce(0) { $0 + $1.duration }
    }
    
    func getLastMonthTotal() -> TimeInterval {
        let calendar = Calendar.current
        let today = Date()
        guard let oneMonthAgo = calendar.date(byAdding: .month, value: -1, to: today),
              let twoMonthsAgo = calendar.date(byAdding: .month, value: -2, to: today) else { return 0 }
        
        return sessions.filter { $0.startTime >= twoMonthsAgo && $0.startTime < oneMonthAgo }
            .reduce(0) { $0 + $1.duration }
    }
    
    // MARK: - Storage & Reports
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
        Last 7 Days: \(formatTimeInterval(getLastWeekTotal()))
        
        [ THIS MONTH ]
        Current: \(formatTimeInterval(getMonthlyTotal()))
        Last 30 Days: \(formatTimeInterval(getLastMonthTotal()))
        ========================================
        
        [ RECENT SESSIONS (LAST 7 DAYS) ]

        """
        
        let calendar = Calendar.current
        let oneWeekAgo = calendar.date(byAdding: .day, value: -7, to: Date())!
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
