import SwiftUI
import Charts
import AppKit
import UniformTypeIdentifiers

extension ReportRange {
    var title: String {
        switch self {
        case .day: return "Günlük"
        case .week: return "Haftalık"
        case .month: return "Aylık"
        case .all: return "Genel"
        }
    }
}

struct ReportsView: View {
    @ObservedObject var timeManager: TimeManager
    let accent: Color
    @State private var range = ReportRange.week
    @State private var selectedDate = Date()
    @State private var followsCurrent = true
    @State private var exportMessage = ""
    @State private var showExportMessage = false

    private var anchor: Date { followsCurrent ? Date() : selectedDate }
    private var snapshot: [TimeSession] { timeManager.reportSessions() }
    private var interval: DateInterval { ReportAnalytics.interval(for: range, containing: anchor, sessions: snapshot) }
    private var segments: [TimeSession] { ReportAnalytics.segments(in: interval, sessions: snapshot) }
    private var buckets: [ReportBucket] { ReportAnalytics.buckets(for: range, in: interval, sessions: snapshot) }
    private var total: TimeInterval { ReportAnalytics.total(in: interval, sessions: snapshot) }
    private var best: ReportBucket? { buckets.filter { $0.duration > 0 }.max { $0.duration < $1.duration } }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack(alignment: .top) {
                PageHeading(eyebrow: "REPORTS", title: "Zamanına bir adım geriden bak.",
                            subtitle: "Günlük detaylardan büyük resme, çalışma ritmin burada.")
                Spacer(minLength: 12)
                Button(action: exportReport) {
                    Label("Dışa aktar", systemImage: "square.and.arrow.up")
                        .font(.system(size: 12, weight: .medium)).padding(10)
                        .background(.white, in: RoundedRectangle(cornerRadius: 10))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(AppColors.border, lineWidth: 1))
                }.buttonStyle(.plain).help("Seçili dönemi metin dosyası olarak kaydet")
            }
            controls
            HStack(spacing: 16) {
                MetricCard(title: range == .all ? "Tüm zamanlar" : "Toplam çalışma", value: TimeText.duration(total),
                           detail: periodTitle, icon: "clock", accent: accent)
                MetricCard(title: "Çalışma kayıtları", value: "\(segments.count)",
                           detail: "Seçili dönemdeki oturumlar", icon: "square.stack.3d.up", accent: accent)
                MetricCard(title: range == .day ? "En uzun oturum" : range == .month ? "En yoğun hafta" : range == .week ? "En yoğun gün" : "En yoğun ay",
                           value: highlightValue, detail: highlightDetail, icon: "sparkles", accent: accent)
            }

            VStack(alignment: .leading, spacing: 22) {
                HStack {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(chartTitle).font(.system(size: 17, weight: .semibold))
                        Text(chartSubtitle).font(.system(size: 12)).foregroundColor(AppColors.muted)
                    }
                    Spacer()
                    Label("Çalışma süresi", systemImage: "circle.fill")
                        .font(.system(size: 10)).foregroundColor(accent)
                }
                if range == .day {
                    DayTimeline(interval: interval, sessions: segments, accent: accent)
                } else {
                    DurationChart(buckets: buckets, range: range, accent: accent)
                }
                if total == 0 {
                    HStack(spacing: 12) {
                        Image(systemName: "leaf").font(.system(size: 22)).foregroundColor(accent)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Bu dönemde henüz çalışma yok.").font(.system(size: 13, weight: .medium))
                            Text("Başka bir tarih seçebilir veya Dashboard'dan yeni bir oturum başlatabilirsin.")
                                .font(.system(size: 12)).foregroundColor(AppColors.muted)
                        }
                    }.padding(.top, 8)
                }
            }.appCard()

            if range != .day && !buckets.isEmpty {
                breakdown
            }
            if !segments.isEmpty { sessionList }
            Label("Saatler Mac'inin yerel saat dilimindedir. Devam eden çalışman da toplamlara dahildir.", systemImage: "info.circle")
                .font(.system(size: 11)).foregroundColor(AppColors.muted)
        }
        .alert("Rapor", isPresented: $showExportMessage) { Button("Tamam", role: .cancel) {} } message: { Text(exportMessage) }
    }

    private var controls: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 5) {
                ForEach(ReportRange.allCases, id: \.self) { option in
                    Button { range = option } label: {
                        Text(option.title).font(.system(size: 13, weight: .semibold))
                            .padding(.horizontal, 24).padding(.vertical, 11)
                            .foregroundColor(range == option ? .white : AppColors.muted)
                            .background(range == option ? accent : .clear, in: RoundedRectangle(cornerRadius: 10))
                    }.buttonStyle(.plain)
                        .accessibilityAddTraits(range == option ? .isSelected : [])
                }
                Spacer()
            }
            HStack(spacing: 12) {
                if range != .all {
                    Button { movePeriod(-1) } label: { Image(systemName: "chevron.left").frame(width: 26, height: 26) }
                        .buttonStyle(.borderless).help("Önceki dönem").accessibilityLabel("Önceki dönem")
                    Text(periodTitle).font(.system(size: 15, weight: .semibold)).lineLimit(1)
                    Button { movePeriod(1) } label: { Image(systemName: "chevron.right").frame(width: 26, height: 26) }
                        .buttonStyle(.borderless).disabled(interval.end > Date()).help("Sonraki dönem").accessibilityLabel("Sonraki dönem")
                    Spacer(minLength: 8)
                    DatePicker("Tarih", selection: Binding(get: { anchor }, set: { selectedDate = $0; followsCurrent = false }),
                               in: ...Date(), displayedComponents: .date)
                        .labelsHidden().datePickerStyle(.field).fixedSize().environment(\.locale, Locale(identifier: "tr_TR"))
                        .accessibilityLabel("Rapor tarihi")
                    Button("Bugüne dön") { selectedDate = Date(); followsCurrent = true }
                        .buttonStyle(.borderless).font(.system(size: 12, weight: .medium))
                } else {
                    Text("Tüm çalışma geçmişin").font(.system(size: 15, weight: .semibold))
                    Spacer()
                    Text(periodTitle).font(.system(size: 12)).foregroundColor(AppColors.muted)
                }
            }
        }.appCard()
    }

    private var periodTitle: String {
        switch range {
        case .day: return TimeText.date(interval.start, "d MMMM yyyy, EEEE")
        case .month: return TimeText.date(interval.start, "MMMM yyyy")
        case .week, .all:
            return "\(TimeText.date(interval.start, "d MMM yyyy")) – \(TimeText.date(interval.end.addingTimeInterval(-1), "d MMM yyyy"))"
        }
    }

    private var chartTitle: String {
        switch range {
        case .day: return "Günün zaman çizelgesi"
        case .week: return "Gün gün çalışma ritmin"
        case .month: return "Haftalara göre çalışma"
        case .all: return "Büyük resim"
        }
    }

    private var chartSubtitle: String {
        switch range {
        case .day: return "00:00 – 24:00 · Çalıştığın saat aralıkları"
        case .week: return "Pazartesiden pazara, her günün toplam süresi"
        case .month: return "Pazartesi – Pazar haftaları · Yalnızca seçili aya düşen günler"
        case .all: return "İlk kaydından bugüne aylık toplamlar · Tüm geçmiş"
        }
    }

    private var highlightValue: String {
        if range == .day { return TimeText.duration(segments.map(\.duration).max() ?? 0) }
        return best.map { TimeText.duration($0.duration) } ?? "—"
    }

    private var highlightDetail: String {
        if range == .day { return "Seçili gündeki en uzun çalışma" }
        return best.map { bucketLabel($0, range: range) } ?? "İlk kaydınla oluşacak"
    }

    private var breakdown: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Sürelerin dağılımı").font(.system(size: 17, weight: .semibold))
            LazyVStack(spacing: 0) {
                ForEach(buckets) { bucket in
                    Button { openBucket(bucket) } label: {
                        HStack(spacing: 18) {
                            Text(bucketLabel(bucket, range: range)).font(.system(size: 12, weight: .medium))
                                .frame(width: 130, alignment: .leading)
                            GeometryReader { proxy in
                                Capsule().fill(accent.opacity(0.07))
                                Capsule().fill(accent.opacity(0.65))
                                    .frame(width: proxy.size.width * bucket.duration / max(1, best?.duration ?? 1))
                            }.frame(height: 7)
                            Text(TimeText.duration(bucket.duration)).font(.system(size: 12, weight: .semibold)).monospacedDigit()
                                .frame(width: 105, alignment: .trailing)
                            Image(systemName: "chevron.right").font(.system(size: 10)).foregroundColor(AppColors.muted)
                        }
                        .padding(.vertical, 13).contentShape(Rectangle())
                    }.buttonStyle(.plain)
                        .help(range == .week ? "Günün saatlerini incele" : range == .month ? "Haftanın tamamını incele" : "Ayı incele")
                    if bucket.id != buckets.last?.id { Divider().overlay(AppColors.border.opacity(0.5)) }
                }
            }
        }.appCard()
    }

    private var sessionList: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(range == .all ? "Son çalışma kayıtları" : "Çalışma aralıkları").font(.system(size: 17, weight: .semibold))
                Spacer()
                Text(range == .all && segments.count > 20 ? "Son 20 kayıt · Toplamlar tüm geçmişi kapsar" : "\(segments.count) kayıt")
                    .font(.system(size: 11)).foregroundColor(AppColors.muted)
            }
            LazyVStack(spacing: 0) {
                ForEach(visibleSessions) { session in
                    HStack(spacing: 14) {
                        Image(systemName: "clock").foregroundColor(accent)
                            .frame(width: 32, height: 32).background(accent.opacity(0.08), in: RoundedRectangle(cornerRadius: 9))
                        VStack(alignment: .leading, spacing: 4) {
                            Text(sessionTimeLabel(session)).font(.system(size: 13, weight: .medium)).monospacedDigit()
                            Text(TimeText.date(session.startTime, "d MMMM yyyy, EEEE"))
                                .font(.system(size: 11)).foregroundColor(AppColors.muted)
                        }
                        Spacer()
                        Text(TimeText.duration(session.duration)).font(.system(size: 13, weight: .semibold)).monospacedDigit()
                    }.padding(.vertical, 10)
                    if session.id != visibleSessions.last?.id { Divider() }
                }
            }
        }.appCard()
    }

    private var visibleSessions: [TimeSession] {
        let sorted = segments.sorted { $0.startTime > $1.startTime }
        return range == .all ? Array(sorted.prefix(20)) : sorted
    }

    private func sessionTimeLabel(_ session: TimeSession) -> String {
        let calendar = Calendar.current
        let end: String
        if range == .day && session.endTime == interval.end {
            end = "24:00"
        } else if !calendar.isDate(session.startTime, inSameDayAs: session.endTime) {
            end = TimeText.date(session.endTime, "d MMM HH:mm:ss")
        } else {
            end = TimeText.date(session.endTime, "HH:mm:ss")
        }
        return "\(TimeText.date(session.startTime, "HH:mm:ss")) – \(end)"
    }

    private func movePeriod(_ offset: Int) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .autoupdatingCurrent
        let component: Calendar.Component = range == .day ? .day : range == .week ? .weekOfYear : .month
        if let moved = calendar.date(byAdding: component, value: offset, to: interval.start) {
            selectedDate = moved
            followsCurrent = false
        }
    }

    private func openBucket(_ bucket: ReportBucket) {
        selectedDate = bucket.start
        followsCurrent = false
        switch range {
        case .week: range = .day
        case .month: range = .week
        case .all: range = .month
        case .day: break
        }
    }

    private func exportReport() {
        // Capture a single snapshot before the save panel runs its modal loop.
        let reportSessions = snapshot
        let reportInterval = ReportAnalytics.interval(for: range, containing: anchor, sessions: reportSessions)
        let reportSegments = ReportAnalytics.segments(in: reportInterval, sessions: reportSessions)
        let reportBuckets = ReportAnalytics.buckets(for: range, in: reportInterval, sessions: reportSessions)
        var text = "SUM TIME · \(range.title) rapor\n\(periodTitle)\nSaat dilimi: \(TimeZone.current.identifier)\n\n"
        text += "Toplam: \(TimeText.clock(ReportAnalytics.total(in: reportInterval, sessions: reportSessions)))\n\n"
        if range != .day {
            for bucket in reportBuckets { text += "\(bucketLabel(bucket, range: range)): \(TimeText.clock(bucket.duration))\n" }
        }
        text += "\nÇALIŞMA ARALIKLARI\n"
        for session in reportSegments {
            text += "\(TimeText.date(session.startTime, "yyyy-MM-dd HH:mm:ss")) – \(TimeText.date(session.endTime, "yyyy-MM-dd HH:mm:ss")) | \(TimeText.clock(session.duration))\n"
        }
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.plainText]
        panel.nameFieldStringValue = "SumTime-\(range.rawValue)-\(TimeText.date(reportInterval.start, "yyyy-MM-dd")).txt"
        panel.directoryURL = SettingsManager.shared.dataFolderURL
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            try text.write(to: url, atomically: true, encoding: .utf8)
            exportMessage = "Rapor kaydedildi: \(url.lastPathComponent)"
        } catch {
            exportMessage = "Rapor kaydedilemedi. \(error.localizedDescription)"
        }
        showExportMessage = true
    }
}

private func bucketLabel(_ bucket: ReportBucket, range: ReportRange) -> String {
    switch range {
    case .day: return TimeText.date(bucket.start, "HH:mm")
    case .week: return TimeText.date(bucket.start, "EEE, d MMM")
    case .month: return "\(TimeText.date(bucket.start, "d")) – \(TimeText.date(bucket.end.addingTimeInterval(-1), "d MMM"))"
    case .all: return TimeText.date(bucket.start, "MMM yyyy")
    }
}

struct DurationChart: View {
    let buckets: [ReportBucket]
    let range: ReportRange
    let accent: Color

    var body: some View {
        GeometryReader { proxy in
            ScrollView(.horizontal) {
                Chart(buckets) { bucket in
                    BarMark(x: .value("Dönem", bucketLabel(bucket, range: range)),
                            y: .value("Saat", bucket.duration / 3600), width: .ratio(0.48))
                        .foregroundStyle(accent.gradient)
                        .cornerRadius(5)
                        .annotation(position: .top) {
                            if bucket.duration > 0 {
                                Text(TimeText.duration(bucket.duration)).font(.system(size: 9, weight: .medium))
                                    .foregroundColor(AppColors.ink)
                            }
                        }
                        .accessibilityLabel(bucketLabel(bucket, range: range))
                        .accessibilityValue(TimeText.duration(bucket.duration))
                }
                .chartYScale(domain: 0...max(1, (buckets.map(\.duration).max() ?? 0) / 3600 * 1.25))
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine().foregroundStyle(AppColors.border)
                        AxisValueLabel {
                            if let hours = value.as(Double.self) { Text("\(hours, specifier: "%g") sa").font(.system(size: 10)) }
                        }
                    }
                }
                .chartXAxis { AxisMarks { _ in AxisValueLabel().font(.system(size: 10)) } }
                .frame(width: max(proxy.size.width, CGFloat(buckets.count) * 85), height: 220)
            }
        }.frame(height: 232)
    }
}

struct DayTimeline: View {
    let interval: DateInterval
    let sessions: [TimeSession]
    let accent: Color

    private func position(_ date: Date, width: CGFloat) -> CGFloat {
        CGFloat(max(0, min(1, date.timeIntervalSince(interval.start) / max(1, interval.duration)))) * width
    }

    private func tick(_ hour: Int) -> Date {
        if hour == 24 { return interval.end }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .autoupdatingCurrent
        return calendar.date(bySettingHour: hour, minute: 0, second: 0, of: interval.start) ?? interval.start
    }

    var body: some View {
        GeometryReader { proxy in
            let width = max(1, proxy.size.width - 36)
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 9).fill(accent.opacity(0.05)).frame(width: width, height: 46).offset(y: 20)
                ForEach([0, 6, 12, 18, 24], id: \.self) { hour in
                    let x = position(tick(hour), width: width)
                    Rectangle().fill(AppColors.border).frame(width: 1, height: 74).offset(x: x, y: 6)
                    Text(String(format: "%02d:00", hour)).font(.system(size: 10)).monospacedDigit()
                        .foregroundColor(AppColors.muted).frame(width: 44).offset(x: x - 22, y: 86)
                }
                ForEach(sessions) { session in
                    let start = position(session.startTime, width: width)
                    let end = position(session.endTime, width: width)
                    RoundedRectangle(cornerRadius: 5).fill(accent.opacity(0.85))
                        .frame(width: max(1, end - start), height: 34).offset(x: start, y: 26)
                        .help("\(TimeText.date(session.startTime, "HH:mm:ss")) – \(session.endTime == interval.end ? "24:00" : TimeText.date(session.endTime, "HH:mm:ss")) · \(TimeText.duration(session.duration))")
                        .accessibilityLabel("Çalışma: \(TimeText.date(session.startTime, "HH:mm")) – \(TimeText.date(session.endTime, "HH:mm")), \(TimeText.duration(session.duration))")
                }
            }.padding(.horizontal, 18)
        }.frame(height: 112)
    }
}
