import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private let manager = WallpaperManager.shared
    private var sleepWakeHandler: SleepWakeHandler!
    private var screenObserver: ScreenObserver!
    private var eventMonitor: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        setupPopover()
        setupStatusBar()

        sleepWakeHandler = SleepWakeHandler(manager: manager)
        screenObserver = ScreenObserver(manager: manager)

        manager.restoreLastSession()
    }

    // MARK: - Popover

    private func setupPopover() {
        popover = NSPopover()
        popover.contentSize = NSSize(width: 320, height: 420)
        popover.behavior = .transient
        popover.animates = true
        popover.contentViewController = NSHostingController(rootView: PopoverView())
    }

    // MARK: - Status Bar

    private func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(
                systemSymbolName: "play.rectangle.fill",
                accessibilityDescription: "LiveWallpaper"
            )
            button.action = #selector(togglePopover)
            button.target = self
        }
    }

    @objc private func togglePopover(_ sender: NSStatusBarButton) {
        if popover.isShown {
            popover.performClose(sender)
        } else {
            popover.show(relativeTo: sender.bounds, of: sender, preferredEdge: .minY)
            // Bring popover to front
            popover.contentViewController?.view.window?.makeKey()
        }
    }
}
