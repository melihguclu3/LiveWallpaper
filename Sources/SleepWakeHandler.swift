import AppKit

/// Handles macOS sleep/wake events to prevent duplicate windows.
///
/// The original app had a bug where waking from sleep created a second
/// video overlay (one small, one fullscreen). The fix:
///   - On sleep: only PAUSE — never destroy windows.
///   - On wake: wait for GPU, validate windows match screens, then resume.
///   - Never create new windows on wake.
final class SleepWakeHandler {
    private weak var manager: WallpaperManager?

    init(manager: WallpaperManager) {
        self.manager = manager

        let ws = NSWorkspace.shared.notificationCenter
        ws.addObserver(self, selector: #selector(willSleep),
                       name: NSWorkspace.willSleepNotification, object: nil)
        ws.addObserver(self, selector: #selector(didWake),
                       name: NSWorkspace.didWakeNotification, object: nil)

        // Also handle screen lock/unlock (similar issue)
        let dn = DistributedNotificationCenter.default()
        dn.addObserver(self, selector: #selector(screenLocked),
                       name: NSNotification.Name("com.apple.screenIsLocked"), object: nil)
        dn.addObserver(self, selector: #selector(screenUnlocked),
                       name: NSNotification.Name("com.apple.screenIsUnlocked"), object: nil)
    }

    deinit {
        NSWorkspace.shared.notificationCenter.removeObserver(self)
        DistributedNotificationCenter.default().removeObserver(self)
    }

    @objc private func willSleep(_ n: Notification) {
        manager?.handleSleep()
    }

    @objc private func didWake(_ n: Notification) {
        manager?.handleWake()
    }

    @objc private func screenLocked(_ n: Notification) {
        manager?.handleSleep()
    }

    @objc private func screenUnlocked(_ n: Notification) {
        manager?.handleWake()
    }
}
