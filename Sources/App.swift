import SwiftUI
import AppKit
import Combine

@main
struct SumTimeTrackerApp {
    @MainActor
    static func main() {
        let application = NSApplication.shared
        let delegate = AppDelegate()
        application.delegate = delegate
        application.setActivationPolicy(.regular)
        withExtendedLifetime(delegate) {
            application.run()
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate {
    private var mainWindow: NSWindow?
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        configureMainMenu()
        configureMenuBar()
        setupNotifications()
        showMainWindow(nil)
    }

    @objc func showMainWindow(_ sender: Any?) {
        popover?.performClose(nil)
        if mainWindow == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 1160, height: 800),
                styleMask: [.titled, .closable, .miniaturizable, .resizable],
                backing: .buffered,
                defer: false
            )
            window.title = "SUM TIME"
            window.titlebarAppearsTransparent = true
            window.backgroundColor = NSColor(calibratedRed: 0.965, green: 0.969, blue: 0.949, alpha: 1)
            window.appearance = NSAppearance(named: .aqua)
            window.contentMinSize = NSSize(width: 980, height: 700)
            window.isReleasedWhenClosed = false
            window.collectionBehavior = [.fullScreenPrimary]
            window.contentViewController = NSHostingController(rootView: ContentView())
            window.center()
            window.setFrameAutosaveName("SumTimeMainWindow")
            mainWindow = window
        }

        TimeManager.shared.checkDayChange(forceRefresh: true)
        mainWindow?.deminiaturize(nil)
        mainWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showMainWindow(nil)
        return true
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // The menu bar remains available while a focus session is running.
        false
    }

    func applicationWillTerminate(_ notification: Notification) {
        TimeManager.shared.stopTracking()
        NSWorkspace.shared.notificationCenter.removeObserver(self)
        NotificationCenter.default.removeObserver(self)
    }

    private func configureMenuBar() {
        let compactPopover = NSPopover()
        compactPopover.contentSize = NSSize(width: 320, height: 350)
        compactPopover.behavior = .transient
        compactPopover.delegate = self
        compactPopover.appearance = NSAppearance(named: .aqua)
        compactPopover.contentViewController = NSHostingController(
            rootView: MenuBarView(
                openApp: { [weak self] in self?.showMainWindow(nil) },
                quitApp: { NSApp.terminate(nil) }
            )
        )
        popover = compactPopover

        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.target = self
        item.button?.action = #selector(togglePopover(_:))
        item.button?.font = NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .medium)
        item.button?.imagePosition = .imageLeading
        statusItem = item

        TimeManager.shared.$isTracking
            .receive(on: RunLoop.main)
            .sink { [weak self] isTracking in
                self?.updateStatusItem(isTracking: isTracking, duration: TimeManager.shared.currentSessionDuration)
            }
            .store(in: &cancellables)

        TimeManager.shared.$currentSessionDuration
            .receive(on: RunLoop.main)
            .sink { [weak self] duration in
                self?.updateStatusItem(isTracking: TimeManager.shared.isTracking, duration: duration)
            }
            .store(in: &cancellables)

        updateStatusItem(isTracking: TimeManager.shared.isTracking, duration: TimeManager.shared.currentSessionDuration)
    }

    private func updateStatusItem(isTracking: Bool, duration: TimeInterval) {
        guard let button = statusItem?.button else { return }
        let image = NSImage(
            systemSymbolName: isTracking ? "timer.circle.fill" : "timer",
            accessibilityDescription: isTracking ? "SUM TIME, çalışma sürüyor" : "SUM TIME"
        )
        image?.isTemplate = true
        button.image = image
        let seconds = max(0, Int(duration))
        button.title = isTracking
            ? String(format: " %02d:%02d:%02d", seconds / 3600, seconds / 60 % 60, seconds % 60)
            : ""
        button.toolTip = isTracking ? "Çalışma sürüyor • Hızlı kontroller için tıkla" : "SUM TIME • Çalışmaya hazır"
    }

    @objc private func togglePopover(_ sender: Any?) {
        guard let button = statusItem?.button, let popover else { return }
        if popover.isShown {
            popover.performClose(sender)
        } else {
            TimeManager.shared.checkDayChange(forceRefresh: true)
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: true)
            popover.contentViewController?.view.window?.makeKey()
        }
    }

    func popoverWillShow(_ notification: Notification) {
        TimeManager.shared.checkDayChange(forceRefresh: true)
    }

    private func setupNotifications() {
        let workspace = NSWorkspace.shared.notificationCenter
        workspace.addObserver(self, selector: #selector(handleSleepOrShutdown), name: NSWorkspace.willSleepNotification, object: nil)
        workspace.addObserver(self, selector: #selector(handleSleepOrShutdown), name: NSWorkspace.willPowerOffNotification, object: nil)
        workspace.addObserver(self, selector: #selector(refreshCalendar), name: NSWorkspace.didWakeNotification, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(refreshCalendar), name: .NSCalendarDayChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(refreshCalendar), name: NSNotification.Name.NSSystemClockDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(refreshCalendar), name: NSNotification.Name.NSSystemTimeZoneDidChange, object: nil)
    }

    @objc private func handleSleepOrShutdown() {
        TimeManager.shared.stopTracking()
    }

    @objc private func refreshCalendar() {
        TimeManager.shared.checkDayChange(forceRefresh: true)
    }

    private func configureMainMenu() {
        let menu = NSMenu()
        let appMenu = NSMenu(title: "SUM TIME")
        appMenu.addItem(withTitle: "SUM TIME Hakkında", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "SUM TIME'ı Gizle", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
        let hideOthers = appMenu.addItem(withTitle: "Diğerlerini Gizle", action: #selector(NSApplication.hideOtherApplications(_:)), keyEquivalent: "h")
        hideOthers.keyEquivalentModifierMask = [.command, .option]
        appMenu.addItem(withTitle: "Tümünü Göster", action: #selector(NSApplication.unhideAllApplications(_:)), keyEquivalent: "")
        appMenu.addItem(.separator())
        let quit = appMenu.addItem(withTitle: "SUM TIME'dan Çık", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        quit.target = NSApp
        addSubmenu(appMenu, to: menu)

        let fileMenu = NSMenu(title: "Dosya")
        let open = fileMenu.addItem(withTitle: "Uygulamayı Aç", action: #selector(showMainWindow(_:)), keyEquivalent: "0")
        open.target = self
        fileMenu.addItem(withTitle: "Pencereyi Kapat", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")
        addSubmenu(fileMenu, to: menu)

        let editMenu = NSMenu(title: "Düzen")
        editMenu.addItem(withTitle: "Geri Al", action: Selector(("undo:")), keyEquivalent: "z")
        let redo = editMenu.addItem(withTitle: "Yinele", action: Selector(("redo:")), keyEquivalent: "z")
        redo.keyEquivalentModifierMask = [.command, .shift]
        editMenu.addItem(.separator())
        editMenu.addItem(withTitle: "Kes", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        editMenu.addItem(withTitle: "Kopyala", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editMenu.addItem(withTitle: "Yapıştır", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        editMenu.addItem(withTitle: "Tümünü Seç", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        addSubmenu(editMenu, to: menu)

        let windowMenu = NSMenu(title: "Pencere")
        windowMenu.addItem(withTitle: "Simge Durumuna Küçült", action: #selector(NSWindow.performMiniaturize(_:)), keyEquivalent: "m")
        windowMenu.addItem(withTitle: "Büyüt", action: #selector(NSWindow.performZoom(_:)), keyEquivalent: "")
        windowMenu.addItem(.separator())
        windowMenu.addItem(withTitle: "Tümünü Öne Getir", action: #selector(NSApplication.arrangeInFront(_:)), keyEquivalent: "")
        addSubmenu(windowMenu, to: menu)
        NSApp.windowsMenu = windowMenu
        NSApp.mainMenu = menu
    }

    private func addSubmenu(_ submenu: NSMenu, to menu: NSMenu) {
        let item = NSMenuItem(title: submenu.title, action: nil, keyEquivalent: "")
        item.submenu = submenu
        menu.addItem(item)
    }
}
