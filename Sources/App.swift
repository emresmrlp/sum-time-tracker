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

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var popover: NSPopover!
    var cancellables = Set<AnyCancellable>()
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        let contentView = ContentView()
        
        popover = NSPopover()
        popover.contentSize = NSSize(width: 360, height: 560)
        popover.behavior = .transient
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
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
                // Bring to front and activate when popover opens
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }
    
    func setupNotifications() {
        let workspaceNotificationCenter = NSWorkspace.shared.notificationCenter
        workspaceNotificationCenter.addObserver(self, selector: #selector(handleSleepOrShutdown), name: NSWorkspace.willSleepNotification, object: nil)
        workspaceNotificationCenter.addObserver(self, selector: #selector(handleSleepOrShutdown), name: NSWorkspace.willPowerOffNotification, object: nil)
    }
    
    @objc func handleSleepOrShutdown() {
        TimeManager.shared.stopTracking()
    }
}
