import AppKit

/// Watches for screen connect/disconnect/resolution changes.
final class ScreenObserver {
    private weak var manager: WallpaperManager?

    init(manager: WallpaperManager) {
        self.manager = manager

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screensChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func screensChanged(_ n: Notification) {
        // Small delay — macOS may send this before screens are fully ready
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.manager?.reconfigureWindows()
        }
    }
}
