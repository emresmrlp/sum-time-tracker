import SwiftUI
import AppKit

struct ContentView: View {
    @StateObject private var settings = SettingsManager.shared
    @StateObject private var timeManager = TimeManager.shared
    
    var body: some View {
        if settings.hasCompletedSetup {
            MainAppView(settings: settings, timeManager: timeManager)
        } else {
            SetupView(settings: settings)
        }
    }
}

struct SetupView: View {
    @ObservedObject var settings: SettingsManager
    @State private var pathError: String? = nil
    
    let bgDark = Color(white: 0.05)
    let bgCard = Color(white: 0.10)
    let strokeColor = Color(white: 0.15)
    let pureWhite = Color.white
    let textMuted = Color(white: 0.55)
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Image(systemName: "timer")
                    .font(.system(size: 32, weight: .light))
                    .foregroundColor(settings.currentAccentColor)
                Text("WELCOME TO SUM TIME")
                    .font(.system(size: 14, weight: .semibold))
                    .letterSpacing(1.5)
                    .foregroundColor(pureWhite)
                Text("Let's quickly set up your tracker.")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(textMuted)
            }
            .padding(.top, 20)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("DATA LOCATION")
                    .font(.system(size: 10, weight: .bold))
                    .letterSpacing(1.2)
                    .foregroundColor(textMuted)
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        TextField("Enter folder path", text: $settings.dataFolderPath)
                            .font(.system(size: 10, weight: .regular, design: .monospaced))
                            .foregroundColor(pureWhite)
                            .textFieldStyle(PlainTextFieldStyle())
                            .onChange(of: settings.dataFolderPath) { _, newValue in
                                validatePath(newValue)
                            }
                        
                        Button("Browse") {
                            let panel = NSOpenPanel()
                            panel.canChooseFiles = false
                            panel.canChooseDirectories = true
                            panel.canCreateDirectories = true
                            panel.prompt = "Select Folder"
                            
                            if panel.runModal() == .OK, let url = panel.url {
                                settings.dataFolderPath = url.path
                                validatePath(url.path)
                            }
                        }
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(settings.currentAccentColor)
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(12)
                    .background(bgCard)
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(pathError == nil ? strokeColor : Color.red, lineWidth: 1))
                    
                    if let error = pathError {
                        Text(error)
                            .font(.system(size: 10, weight: .regular))
                            .foregroundColor(.red)
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text("THEME COLOR")
                    .font(.system(size: 10, weight: .bold))
                    .letterSpacing(1.2)
                    .foregroundColor(textMuted)
                
                HStack(spacing: 12) {
                    ForEach(0..<settings.colorPalette.count, id: \.self) { index in
                        Circle()
                            .fill(settings.colorPalette[index])
                            .frame(width: 24, height: 24)
                            .overlay(
                                Circle()
                                    .stroke(pureWhite, lineWidth: settings.accentColorIndex == index ? 2 : 0)
                                    .padding(-4)
                            )
                            .onTapGesture {
                                withAnimation {
                                    settings.accentColorIndex = index
                                }
                            }
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity)
                .background(bgCard)
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(strokeColor, lineWidth: 1))
            }
            
            Spacer()
            
            Button(action: {
                if pathError == nil {
                    withAnimation {
                        settings.hasCompletedSetup = true
                    }
                }
            }) {
                Text("GET STARTED")
                    .font(.system(size: 12, weight: .bold))
                    .letterSpacing(1.0)
                    .foregroundColor(pureWhite)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(pathError == nil ? settings.currentAccentColor : Color.gray)
                    .cornerRadius(22)
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(pathError != nil)
            
            HStack {
                Spacer()
                Button(action: {
                    NSApplication.shared.terminate(nil)
                }) {
                    Text("Quit")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(textMuted)
                }
                .buttonStyle(PlainButtonStyle())
                Spacer()
            }
        }
        .padding(32)
        .frame(width: 360, height: 560)
        .background(bgDark)
        .onAppear {
            validatePath(settings.dataFolderPath)
        }
    }
    
    private func validatePath(_ path: String) {
        if path.isEmpty {
            pathError = "Path cannot be empty."
            return
        }
        
        var isDir: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: path, isDirectory: &isDir)
        
        if !exists {
            pathError = "Directory does not exist."
        } else if !isDir.boolValue {
            pathError = "Path is a file, not a directory."
        } else {
            pathError = nil
        }
    }
}

struct MainAppView: View {
    @ObservedObject var settings: SettingsManager
    @ObservedObject var timeManager: TimeManager
    @State private var selectedTab = 0
    
    let pureWhite = Color.white
    let bgDark = Color(white: 0.05)
    let bgCard = Color(white: 0.10)
    let strokeColor = Color(white: 0.15)
    let textMuted = Color(white: 0.55)
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "timer")
                        .foregroundColor(timeManager.isTracking ? settings.currentAccentColor : pureWhite)
                        .font(.system(size: 16, weight: .light))
                    Text("SUM TIME")
                        .font(.system(size: 13, weight: .semibold, design: .default))
                        .letterSpacing(1.5)
                        .foregroundColor(pureWhite)
                }
                Spacer()
                
                Button(action: {
                    withAnimation {
                        settings.hasCompletedSetup = false // Go back to settings
                    }
                }) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(textMuted)
                        .frame(width: 28, height: 28)
                        .background(bgCard)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(strokeColor, lineWidth: 0.5))
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: {
                    if timeManager.isTracking {
                        timeManager.stopTracking()
                    }
                    NSApplication.shared.terminate(nil)
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(textMuted)
                        .frame(width: 28, height: 28)
                        .background(bgCard)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(strokeColor, lineWidth: 0.5))
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 16)
            
            // Tab Selector
            HStack(spacing: 16) {
                TabButton(title: "DASHBOARD", isSelected: selectedTab == 0, activeColor: pureWhite, textMuted: textMuted) {
                    withAnimation(.easeInOut(duration: 0.2)) { selectedTab = 0 }
                }
                TabButton(title: "REPORTS", isSelected: selectedTab == 1, activeColor: pureWhite, textMuted: textMuted) {
                    withAnimation(.easeInOut(duration: 0.2)) { selectedTab = 1 }
                }
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
            
            Divider().background(strokeColor)
            
            // Content
            ZStack {
                if selectedTab == 0 {
                    ScrollView(.vertical, showsIndicators: false) {
                        DashboardView(timeManager: timeManager, accentColor: settings.currentAccentColor, pureWhite: pureWhite, bgCard: bgCard, strokeColor: strokeColor, textMuted: textMuted)
                    }
                    .transition(.opacity.combined(with: .move(edge: .leading)))
                } else {
                    ScrollView(.vertical, showsIndicators: false) {
                        ReportsView(timeManager: timeManager, accentColor: settings.currentAccentColor, pureWhite: pureWhite, bgCard: bgCard, strokeColor: strokeColor, textMuted: textMuted)
                    }
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: 360, height: 560)
        .background(bgDark)
    }
}

// MARK: - Subviews

struct TabButton: View {
    let title: String
    let isSelected: Bool
    let activeColor: Color
    let textMuted: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .letterSpacing(1.0)
                    .foregroundColor(isSelected ? activeColor : textMuted)
                
                Rectangle()
                    .fill(isSelected ? activeColor : Color.clear)
                    .frame(height: 1)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

extension View {
    func letterSpacing(_ spacing: CGFloat) -> some View {
        self.kerning(spacing)
    }
}

struct DashboardView: View {
    @ObservedObject var timeManager: TimeManager
    let accentColor: Color
    let pureWhite: Color
    let bgCard: Color
    let strokeColor: Color
    let textMuted: Color
    
    var body: some View {
        VStack(spacing: 40) {
            
            VStack(spacing: 4) {
                Text("TODAY'S WORK")
                    .font(.system(size: 10, weight: .semibold))
                    .letterSpacing(1.2)
                    .foregroundColor(textMuted)
                Text(formatTimeInterval(timeManager.getTodayTotal()))
                    .font(.system(size: 32, weight: .ultraLight, design: .default))
                    .foregroundColor(pureWhite)
            }
            .padding(.top, 20)
            
            ZStack {
                Circle()
                    .stroke(bgCard, lineWidth: 2)
                    .frame(width: 220, height: 220)
                
                Circle()
                    .trim(from: 0, to: 1)
                    .stroke(timeManager.isTracking ? accentColor : strokeColor, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-90))
                    .shadow(color: timeManager.isTracking ? accentColor.opacity(0.3) : .clear, radius: 12, x: 0, y: 0)
                
                VStack(spacing: 8) {
                    Text(formatTimeInterval(timeManager.currentSessionDuration))
                        .font(.system(size: 42, weight: .light, design: .default))
                        .foregroundColor(timeManager.isTracking ? accentColor : pureWhite)
                    
                    Text(timeManager.isTracking ? "RECORDING" : "IDLE")
                        .font(.system(size: 10, weight: .bold))
                        .letterSpacing(1.5)
                        .foregroundColor(timeManager.isTracking ? accentColor : textMuted)
                }
            }
            
            Button(action: {
                withAnimation(.easeOut(duration: 0.3)) {
                    timeManager.toggleTracking()
                }
            }) {
                HStack(spacing: 10) {
                    Image(systemName: timeManager.isTracking ? "stop.fill" : "play.fill")
                        .font(.system(size: 10))
                    Text(timeManager.isTracking ? "STOP" : "START")
                        .font(.system(size: 11, weight: .semibold))
                        .letterSpacing(1.0)
                }
                .foregroundColor(timeManager.isTracking ? bgCard : pureWhite)
                .frame(width: 140, height: 40)
                .background(timeManager.isTracking ? pureWhite : bgCard)
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(strokeColor, lineWidth: timeManager.isTracking ? 0 : 1))
                .cornerRadius(20)
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
        }
    }
}

struct ReportsView: View {
    @ObservedObject var timeManager: TimeManager
    let accentColor: Color
    let pureWhite: Color
    let bgCard: Color
    let strokeColor: Color
    let textMuted: Color
    
    @State private var showCopiedAlert = false
    @State private var alertMessage = ""
    @State private var isError = false
    
    var body: some View {
        VStack(spacing: 24) {
            
            VStack(spacing: 12) {
                ComparisonCard(title: "TODAY", current: timeManager.getTodayTotal(), previous: timeManager.getYesterdayTotal(), prevLabel: "Yesterday", bg: bgCard, stroke: strokeColor, textMuted: textMuted, pureWhite: pureWhite)
                
                ComparisonCard(title: "THIS WEEK", current: timeManager.getWeeklyTotal(), previous: timeManager.getLastWeekTotal(), prevLabel: "Last Week", bg: bgCard, stroke: strokeColor, textMuted: textMuted, pureWhite: pureWhite)
                
                ComparisonCard(title: "THIS MONTH", current: timeManager.getMonthlyTotal(), previous: timeManager.getLastMonthTotal(), prevLabel: "Last Month", bg: bgCard, stroke: strokeColor, textMuted: textMuted, pureWhite: pureWhite)
            }
            
            Spacer()
            
            VStack(spacing: 8) {
                Button(action: {
                    do {
                        try timeManager.generateReport()
                        alertMessage = "Report saved to data folder"
                        isError = false
                    } catch {
                        alertMessage = "Already created a report this minute!"
                        isError = true
                    }
                    
                    withAnimation { showCopiedAlert = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation { showCopiedAlert = false }
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "doc.text")
                        Text("GENERATE REPORT")
                            .font(.system(size: 11, weight: .semibold))
                            .letterSpacing(1.0)
                    }
                    .foregroundColor(pureWhite)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(bgCard)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(strokeColor, lineWidth: 1))
                    .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
                
                if showCopiedAlert {
                    Text(alertMessage)
                        .font(.system(size: 10, weight: .regular))
                        .foregroundColor(isError ? .red : accentColor)
                        .transition(.opacity)
                } else {
                    Text("")
                        .font(.system(size: 10))
                        .opacity(0)
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 24)
    }
}

struct ComparisonCard: View {
    let title: String
    let current: TimeInterval
    let previous: TimeInterval
    let prevLabel: String
    let bg: Color
    let stroke: Color
    let textMuted: Color
    let pureWhite: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 10, weight: .bold))
                .letterSpacing(1.2)
                .foregroundColor(textMuted)
            
            HStack(alignment: .bottom) {
                Text(formatTimeInterval(current))
                    .font(.system(size: 24, weight: .light))
                    .foregroundColor(pureWhite)
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(formatTimeInterval(previous))
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(textMuted)
                    Text(prevLabel)
                        .font(.system(size: 9, weight: .regular))
                        .foregroundColor(textMuted.opacity(0.8))
                }
            }
        }
        .padding(16)
        .background(bg)
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(stroke, lineWidth: 0.5))
    }
}

func formatTimeInterval(_ interval: TimeInterval) -> String {
    let hours = Int(interval) / 3600
    let minutes = Int(interval) / 60 % 60
    let seconds = Int(interval) % 60
    return String(format: "%02i:%02i:%02i", hours, minutes, seconds)
}
