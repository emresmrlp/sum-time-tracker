import SwiftUI
import AppKit
import Combine

@main
struct SumTimeTrackerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate {
    var statusItem: NSStatusItem!
    var popover: NSPopover!
    var cancellables = Set<AnyCancellable>()
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        let contentView = ContentView()
        
        popover = NSPopover()
        popover.contentSize = NSSize(width: 360, height: 560)
        popover.behavior = .transient
        popover.delegate = self
        popover.contentViewController = NSHostingController(rootView: contentView)
        
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            button.action = #selector(togglePopover(_:))
            updateIcon(isTracking: false)
        }
        
        setupNotifications()
        
        TimeManager.shared.$isTracking
            .receive(on: RunLoop.main)
            .sink { [weak self] isTracking in
                self?.updateIcon(isTracking: isTracking)
            }.store(in: &cancellables)
            
        let hasCompletedSetup = UserDefaults.standard.bool(forKey: "hasCompletedSetup")
        if !hasCompletedSetup {
            showWelcomeAlert()
        } else {
            showReadyAlert()
        }
    }
    
    func showReadyAlert() {
        let alert = NSAlert()
        alert.messageText = "Sum Time Tracker is Ready"
        alert.informativeText = "The application is running in the background. You can start the tracker from the menu bar icon in the top right corner."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        
        NSApp.activate(ignoringOtherApps: true)
        alert.runModal()
    }
    
    func showWelcomeAlert() {
        let alert = NSAlert()
        alert.messageText = "Welcome to Sum Time Tracker!"
        alert.informativeText = "Sum Time Tracker is a menu bar application.\n\nYou can access and control the tracker strictly by clicking the timer icon in the top right corner of your screen (Menu Bar).\n\nPlease complete the initial setup to begin tracking your time."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Got it")
        alert.addButton(withTitle: "GitHub Page")
        
        NSApp.activate(ignoringOtherApps: true)
        let response = alert.runModal()
        
        if response == .alertSecondButtonReturn {
            if let url = URL(string: "https://github.com/emresmrlp/sum-time-tracker") {
                NSWorkspace.shared.open(url)
            }
        }
    }
    
    func updateIcon(isTracking: Bool) {
        if let button = statusItem.button {
            let iconName = isTracking ? "timer.circle.fill" : "timer"
            let image = NSImage(systemSymbolName: iconName, accessibilityDescription: "Sum Time Tracker")
            image?.isTemplate = true
            button.image = image
        }
    }
    
    @objc func togglePopover(_ sender: AnyObject?) {
        if let button = statusItem.button {
            if popover.isShown {
                popover.performClose(sender)
            } else {
                TimeManager.shared.checkDayChange(forceRefresh: true)
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
                // Bring to front and activate when popover opens
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }
    
    func popoverWillShow(_ notification: Notification) {
        TimeManager.shared.checkDayChange(forceRefresh: true)
    }
    
    func setupNotifications() {
        let workspaceNotificationCenter = NSWorkspace.shared.notificationCenter
        workspaceNotificationCenter.addObserver(self, selector: #selector(handleSleepOrShutdown), name: NSWorkspace.willSleepNotification, object: nil)
        workspaceNotificationCenter.addObserver(self, selector: #selector(handleSleepOrShutdown), name: NSWorkspace.willPowerOffNotification, object: nil)
        workspaceNotificationCenter.addObserver(self, selector: #selector(handleWake), name: NSWorkspace.didWakeNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleDayChanged), name: .NSCalendarDayChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleDayChanged), name: NSNotification.Name.NSSystemClockDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleDayChanged), name: NSNotification.Name.NSSystemTimeZoneDidChange, object: nil)
    }
    
    @objc func handleSleepOrShutdown() {
        TimeManager.shared.stopTracking()
    }
    
    @objc func handleWake() {
        TimeManager.shared.checkDayChange(forceRefresh: true)
    }
    
    @objc func handleDayChanged() {
        TimeManager.shared.checkDayChange(forceRefresh: true)
    }
}
