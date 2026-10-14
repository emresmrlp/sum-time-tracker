import Foundation

struct TimeSession: Codable, Identifiable {
    var id = UUID()
    var startTime: Date
    var endTime: Date
    var duration: TimeInterval
}
