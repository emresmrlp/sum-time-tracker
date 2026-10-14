import SwiftUI

struct ContentView: View {
    @ObservedObject private var settings = SettingsManager.shared
    @ObservedObject private var timeManager = TimeManager.shared

    var body: some View {
        Group {
            if settings.hasCompletedSetup {
                MainAppView(settings: settings, timeManager: timeManager)
            } else {
                SetupView(settings: settings)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(AppColors.background)
            }
        }
        .tint(settings.currentAccentColor)
        .preferredColorScheme(.light)
        .onChange(of: settings.hasCompletedSetup) { complete in
            if complete { timeManager.reloadSessionsAfterSetup() }
        }
    }
}

private enum AppSection: String, CaseIterable {
    case dashboard = "Dashboard"
    case reports = "Reports"
    case settings = "Ayarlar"

    var icon: String {
        switch self {
        case .dashboard: return "square.grid.2x2"
        case .reports: return "chart.bar.xaxis"
        case .settings: return "slider.horizontal.3"
        }
    }
}

struct MainAppView: View {
    @ObservedObject var settings: SettingsManager
    @ObservedObject var timeManager: TimeManager
    @State private var selection = AppSection.dashboard

    var body: some View {
        HStack(spacing: 0) {
            sidebar
            Rectangle().fill(AppColors.border).frame(width: 1)
            ScrollView {
                Group {
                    switch selection {
                    case .dashboard:
                        DashboardView(timeManager: timeManager, accent: settings.currentAccentColor) {
                            selection = .reports
                        }
                    case .reports:
                        ReportsView(timeManager: timeManager, accent: settings.currentAccentColor)
                    case .settings:
                        SettingsView(settings: settings)
                    }
                }
                .padding(32)
                .frame(maxWidth: 1240)
                .frame(maxWidth: .infinity)
            }
            .background(AppColors.background)
            .id(selection)
        }
        .foregroundColor(AppColors.ink)
        .onAppear { timeManager.checkDayChange(forceRefresh: true) }
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                Image(systemName: "timer")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(settings.currentAccentColor)
                    .frame(width: 44, height: 44)
                    .background(settings.currentAccentColor.opacity(0.1), in: RoundedRectangle(cornerRadius: 14))
                VStack(alignment: .leading, spacing: 3) {
                    Text("sum time").font(.system(size: 21, weight: .bold, design: .rounded))
                    Text("Zamanın sana ait.").font(.system(size: 11)).foregroundColor(AppColors.muted)
                }
            }
            .padding(.bottom, 42)

            Text("ÇALIŞMA ALANIN").font(.system(size: 10, weight: .semibold)).tracking(1.4)
                .foregroundColor(AppColors.muted).padding(.leading, 12).padding(.bottom, 14)

            ForEach(AppSection.allCases, id: \.self) { section in
                Button {
                    selection = section
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: section.icon).font(.system(size: 16)).frame(width: 20)
                        Text(section.rawValue).font(.system(size: 14, weight: selection == section ? .semibold : .medium))
                        Spacer()
                        if selection == section {
                            Circle().fill(settings.currentAccentColor).frame(width: 6, height: 6)
                        }
                    }
                    .padding(.horizontal, 14).padding(.vertical, 14)
                    .foregroundColor(selection == section ? settings.currentAccentColor : AppColors.muted)
                    .background(selection == section ? settings.currentAccentColor.opacity(0.09) : .clear,
                                in: RoundedRectangle(cornerRadius: 12))
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.bottom, 6)
                .accessibilityAddTraits(selection == section ? .isSelected : [])
            }

            Spacer(minLength: 32)

            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: "leaf").font(.system(size: 23, weight: .light)).foregroundColor(settings.currentAccentColor)
                Text("Biraz odak,\nbiraz mola.").font(.system(size: 17, weight: .semibold, design: .rounded))
                Text("Kendi ritmini bul. Her küçük adım birikir.")
                    .font(.system(size: 12)).foregroundColor(AppColors.muted).lineSpacing(4)
            }
            .padding(18).frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColors.background, in: RoundedRectangle(cornerRadius: 16))

            Divider().padding(.vertical, 22)
            HStack(spacing: 9) {
                Circle().fill(timeManager.isTracking ? settings.currentAccentColor : AppColors.muted.opacity(0.5))
                    .frame(width: 7, height: 7)
                VStack(alignment: .leading, spacing: 4) {
                    Text(timeManager.isTracking ? "Odak zamanı" : "Başlamaya hazır")
                        .font(.system(size: 12, weight: .semibold))
                    Text(timeManager.isTracking ? TimeText.clock(timeManager.currentSessionDuration) : "Bugün güzel işler yapalım.")
                        .font(.system(size: 11)).monospacedDigit().foregroundColor(AppColors.muted)
                }
                Spacer(minLength: 0)
            }
        }
        .padding(22)
        .frame(width: 218)
        .frame(maxHeight: .infinity)
        .background(Color.white)
    }
}

struct DashboardView: View {
    @ObservedObject var timeManager: TimeManager
    let accent: Color
    let openReports: () -> Void

    private var snapshot: [TimeSession] { timeManager.reportSessions() }
    private var today: DateInterval {
        ReportAnalytics.interval(for: .day, containing: Date(), sessions: snapshot)
    }
    private var todaySessions: [TimeSession] { ReportAnalytics.segments(in: today, sessions: snapshot) }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            PageHeading(eyebrow: TimeText.date(Date(), "EEEE, d MMMM"), title: "Kendi ritminde çalış.",
                        subtitle: "Odağını bul, zamanını tanı. Gerisini birlikte takip edelim.")
            focusCard
            HStack(spacing: 16) {
                MetricCard(title: "Bugün", value: TimeText.duration(timeManager.getTodayTotal()),
                           detail: "\(todaySessions.count) çalışma oturumu", icon: "sun.max", accent: accent)
                MetricCard(title: "Bu hafta", value: TimeText.duration(timeManager.getWeeklyTotal()),
                           detail: "Pazartesi – Pazar", icon: "calendar", accent: accent)
                MetricCard(title: "Bu ay", value: TimeText.duration(timeManager.getMonthlyTotal()),
                           detail: TimeText.date(Date(), "MMMM yyyy"), icon: "chart.bar", accent: accent)
            }
            VStack(alignment: .leading, spacing: 22) {
                HStack {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Bugünün ritmi").font(.system(size: 17, weight: .semibold))
                        Text("Çalıştığın anlar, tek bir çizgide.").font(.system(size: 12)).foregroundColor(AppColors.muted)
                    }
                    Spacer()
                    Button(action: openReports) {
                        Label("Raporları keşfet", systemImage: "arrow.up.right")
                            .font(.system(size: 12, weight: .semibold))
                    }.buttonStyle(.plain).foregroundColor(accent)
                }
                DayTimeline(interval: today, sessions: todaySessions, accent: accent)
                if todaySessions.isEmpty {
                    Text("İlk oturumunla bu çizgi renklenmeye başlayacak.")
                        .font(.system(size: 12)).foregroundColor(AppColors.muted)
                }
            }.appCard()
            HStack(spacing: 8) {
                Image(systemName: "menubar.rectangle")
                Text("Pencereyi kapatsan da sayacın üst çubukta yanında. Mac uykuya geçtiğinde durur.")
            }
            .font(.system(size: 11)).foregroundColor(AppColors.muted)
        }
    }

    private var focusCard: some View {
        HStack(spacing: 30) {
            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 7) {
                    Circle().fill(accent).frame(width: 7, height: 7)
                    Text(timeManager.isTracking ? "ŞİMDİ ODAK ZAMANI" : "YENİ BİR BAŞLANGIÇ")
                        .font(.system(size: 10, weight: .bold)).tracking(1.5)
                }.foregroundColor(accent)
                Text(TimeText.clock(timeManager.currentSessionDuration))
                    .font(.system(size: 58, weight: .medium, design: .rounded)).monospacedDigit()
                    .accessibilityLabel("Oturum süresi \(TimeText.duration(timeManager.currentSessionDuration))")
                Text(timeManager.isTracking ? "Sen işine odaklan. Zamanın kayıtta." : "Bir nefes al. Hazır olduğunda başlayalım.")
                    .font(.system(size: 14)).foregroundColor(AppColors.muted)
                Button(action: timeManager.toggleTracking) {
                    Label(timeManager.isTracking ? "Molaya geç" : "Çalışmaya başla",
                          systemImage: timeManager.isTracking ? "pause.fill" : "play.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .padding(.horizontal, 24).padding(.vertical, 14)
                        .foregroundColor(.white)
                        .background(accent, in: Capsule())
                }
                .buttonStyle(.plain)
                .help(timeManager.isTracking ? "Oturumu kaydet ve sayacı durdur" : "Yeni bir çalışma oturumu başlat")
            }
            Spacer(minLength: 0)
            ZStack {
                Circle().stroke(accent.opacity(0.08), lineWidth: 1).frame(width: 188, height: 188)
                Circle().stroke(accent.opacity(0.12), lineWidth: 1).frame(width: 154, height: 154)
                Circle().fill(accent.opacity(0.08)).frame(width: 116, height: 116)
                Image(systemName: timeManager.isTracking ? "leaf.fill" : "cup.and.saucer.fill")
                    .font(.system(size: 43, weight: .light)).foregroundColor(accent)
                Image(systemName: "sparkle").font(.system(size: 18)).foregroundColor(accent.opacity(0.6)).offset(x: 70, y: -56)
                Circle().fill(accent.opacity(0.3)).frame(width: 9, height: 9).offset(x: -80, y: 38)
            }.accessibilityHidden(true)
        }
        .padding(30)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(accent.opacity(0.065), in: RoundedRectangle(cornerRadius: 24))
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(accent.opacity(0.12), lineWidth: 1))
    }
}
