import SwiftUI

struct MenuBarView: View {
    @ObservedObject private var timeManager = TimeManager.shared
    @ObservedObject private var settings = SettingsManager.shared

    let openApp: () -> Void
    let quitApp: () -> Void

    private let ink = Color(red: 0.16, green: 0.23, blue: 0.19)
    private var green: Color { settings.currentAccentColor }
    private let muted = Color(red: 0.48, green: 0.53, blue: 0.48)
    private let cream = Color(red: 0.965, green: 0.969, blue: 0.949)

    var body: some View {
        VStack(spacing: 18) {
            HStack {
                Image(systemName: "timer")
                    .font(.system(size: 16, weight: .semibold))
                Text("SUM TIME")
                    .font(.system(size: 12, weight: .bold))
                    .tracking(1.2)
                Spacer()
                Circle()
                    .fill(timeManager.isTracking ? green : muted.opacity(0.4))
                    .frame(width: 6, height: 6)
                Text(timeManager.isTracking ? "Çalışılıyor" : "Hazır")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(muted)
            }

            VStack(spacing: 5) {
                Text(clock(timeManager.currentSessionDuration))
                    .font(.system(size: 40, weight: .medium, design: .rounded))
                    .monospacedDigit()
                Text(settings.hasCompletedSetup
                     ? (timeManager.isTracking ? "Güzel gidiyor, odağını koru." : "Küçük bir adımla başla.")
                     : "Başlamak için kurulumunu tamamla.")
                    .font(.system(size: 12))
                    .foregroundStyle(muted)
            }

            HStack(spacing: 1) {
                total("BUGÜN", duration: timeManager.getTodayTotal())
                Rectangle()
                    .fill(muted.opacity(0.18))
                    .frame(width: 1, height: 30)
                total("BU HAFTA", duration: timeManager.getWeeklyTotal())
            }
            .padding(.vertical, 12)
            .background(Color.white.opacity(0.75), in: RoundedRectangle(cornerRadius: 12))

            Button {
                timeManager.toggleTracking()
            } label: {
                Label(timeManager.isTracking ? "Molaya geç" : "Çalışmaya başla", systemImage: timeManager.isTracking ? "pause.fill" : "play.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 42)
                    .foregroundStyle(.white)
                    .background(settings.hasCompletedSetup ? green : muted, in: RoundedRectangle(cornerRadius: 11))
            }
            .buttonStyle(.plain)
            .disabled(!settings.hasCompletedSetup)

            HStack {
                Button(action: openApp) {
                    Label(settings.hasCompletedSetup ? "Uygulamayı aç" : "Kurulumu tamamla", systemImage: "macwindow")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(green)
                }
                Spacer()
                Button("Çıkış", action: quitApp)
                    .font(.system(size: 12))
                    .foregroundStyle(muted)
            }
            .buttonStyle(.plain)
        }
        .padding(22)
        .frame(width: 320, height: 350)
        .background(cream)
        .foregroundStyle(ink)
        .preferredColorScheme(.light)
    }

    private func total(_ title: String, duration: TimeInterval) -> some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.system(size: 9, weight: .semibold))
                .tracking(1)
                .foregroundStyle(muted)
            Text(durationLabel(duration))
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity)
    }

    private func clock(_ duration: TimeInterval) -> String {
        let seconds = max(0, Int(duration))
        return String(format: "%02d:%02d:%02d", seconds / 3600, seconds / 60 % 60, seconds % 60)
    }

    private func durationLabel(_ duration: TimeInterval) -> String {
        let minutes = max(0, Int(duration) / 60)
        return "\(minutes / 60) sa \(minutes % 60) dk"
    }
}
