import SwiftUI

enum AppColors {
    static let background = Color(red: 0.965, green: 0.973, blue: 0.957)
    static let ink = Color(red: 0.12, green: 0.20, blue: 0.16)
    static let muted = Color(red: 0.43, green: 0.49, blue: 0.45)
    static let border = Color(red: 0.88, green: 0.91, blue: 0.88)
}

extension View {
    func appCard() -> some View {
        self.padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.white, in: RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(AppColors.border.opacity(0.8), lineWidth: 1))
    }
}

enum TimeText {
    static func clock(_ interval: TimeInterval) -> String {
        let value = max(0, Int(interval))
        return String(format: "%02d:%02d:%02d", value / 3600, value / 60 % 60, value % 60)
    }

    static func duration(_ interval: TimeInterval) -> String {
        let seconds = max(0, Int(interval))
        if seconds == 0 { return "0 dk" }
        if seconds < 60 { return "\(seconds) sn" }
        let minutes = seconds / 60
        if minutes < 60 { return "\(minutes) dk" }
        return "\(minutes / 60) sa \(minutes % 60) dk"
    }

    static func date(_ date: Date, _ format: String) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = .autoupdatingCurrent
        formatter.dateFormat = format
        return formatter.string(from: date)
    }
}

struct PageHeading: View {
    let eyebrow: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(eyebrow.uppercased(with: Locale(identifier: "tr_TR")))
                .font(.system(size: 10, weight: .semibold)).tracking(1.5).foregroundColor(AppColors.muted)
            Text(title).font(.system(size: 29, weight: .bold, design: .rounded)).foregroundColor(AppColors.ink)
            Text(subtitle).font(.system(size: 13)).foregroundColor(AppColors.muted)
        }.padding(.bottom, 4)
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let detail: String
    let icon: String
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title).font(.system(size: 12, weight: .medium)).foregroundColor(AppColors.muted)
                Spacer()
                Image(systemName: icon).foregroundColor(accent).font(.system(size: 15))
            }
            Text(value).font(.system(size: 25, weight: .semibold, design: .rounded))
                .monospacedDigit().lineLimit(1).minimumScaleFactor(0.65)
            Text(detail).font(.system(size: 11)).foregroundColor(AppColors.muted)
                .lineLimit(2).frame(height: 28, alignment: .topLeading)
        }.appCard()
    }
}

func formatTimeInterval(_ interval: TimeInterval) -> String { TimeText.clock(interval) }
