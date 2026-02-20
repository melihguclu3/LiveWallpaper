import AppKit

// MARK: - Types

enum MediaSource: Equatable {
    case video(URL)
    case gif(URL)

    var url: URL {
        switch self {
        case .video(let u), .gif(let u): return u
        }
    }

    var displayName: String { url.lastPathComponent }

    var typeKey: String {
        switch self {
        case .video: return "video"
        case .gif:   return "gif"
        }
    }
}

enum PlaybackState {
    case stopped, playing, paused
}

// MARK: - WallpaperManager

final class WallpaperManager {
    static let shared = WallpaperManager()

    private(set) var state: PlaybackState = .stopped
    private(set) var currentSource: MediaSource?

    var isMuted: Bool {
        get { Defaults.isMuted }
        set { Defaults.isMuted = newValue; applyMuteToAll() }
    }

    var showOnAllScreens: Bool {
        get { Defaults.showOnAllScreens }
        set {
            Defaults.showOnAllScreens = newValue
            guard state != .stopped else { return }
            reconfigureWindows()
        }
    }

    var currentFileName: String? { currentSource?.displayName }
    var onStateChange: (() -> Void)?

    /// Windows tracked by stable screen display ID (survives sleep/wake).
    private var windows: [CGDirectDisplayID: WallpaperWindow] = [:]

    private init() {}

    // MARK: - Playback

    func play(source: MediaSource) {
        stop()
        currentSource = source
        createWindowsForTargetScreens()
        state = .playing
        Defaults.lastSourceURL = source.url
        Defaults.lastSourceType = source.typeKey
        onStateChange?()
    }

    func pause() {
        guard state == .playing else { return }
        windows.values.forEach { $0.pauseContent() }
        state = .paused
        onStateChange?()
    }

    func resume() {
        guard state == .paused else { return }
        windows.values.forEach { $0.resumeContent() }
        state = .playing
        onStateChange?()
    }

    func stop() {
        for (_, w) in windows {
            w.stopContent()
            w.orderOut(nil)
        }
        windows.removeAll()
        currentSource = nil
        state = .stopped
        onStateChange?()
    }

    // MARK: - Window Management

    private func createWindowsForTargetScreens() {
        guard let source = currentSource else { return }
        for screen in targetScreens() {
            let id = screen.screenID
            guard windows[id] == nil else { continue }
            let w = WallpaperWindow(screen: screen)
            w.setContent(for: source, muted: isMuted)
            w.orderFrontRegardless()
            windows[id] = w
        }
    }

    /// Sync windows with current screen set — add, remove, resize as needed.
    func reconfigureWindows() {
        guard let source = currentSource, state != .stopped else { return }

        let screens = targetScreens()
        let activeIDs = Set(screens.map(\.screenID))

        // Remove windows for gone screens
        for id in windows.keys where !activeIDs.contains(id) {
            windows[id]?.stopContent()
            windows[id]?.orderOut(nil)
            windows.removeValue(forKey: id)
        }

        // Add or resize
        for screen in screens {
            let id = screen.screenID
            if let existing = windows[id] {
                // Screen may have changed resolution
                existing.setFrame(screen.frame, display: true)
                existing.resizeContent()
            } else {
                let w = WallpaperWindow(screen: screen)
                w.setContent(for: source, muted: isMuted)
                if state == .playing { w.orderFrontRegardless() }
                windows[id] = w
            }
        }
    }

    // MARK: - Sleep / Wake  (fixes duplicate-window bug)

    func handleSleep() {
        // Pause playback but keep windows alive — never destroy on sleep.
        windows.values.forEach { $0.pauseContent() }
    }

    func handleWake() {
        guard state == .playing else { return }
        // GPU needs a moment after wake — wait, then validate & resume.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self, self.state == .playing else { return }
            self.reconfigureWindows()
            self.windows.values.forEach { $0.resumeContent() }
        }
    }

    // MARK: - Restore

    func restoreLastSession() {
        guard let url = Defaults.lastSourceURL,
              FileManager.default.fileExists(atPath: url.path) else { return }
        let type = Defaults.lastSourceType
        let source: MediaSource = (type == "gif") ? .gif(url) : .video(url)
        play(source: source)
    }

    // MARK: - Helpers

    private func targetScreens() -> [NSScreen] {
        showOnAllScreens ? NSScreen.screens : [NSScreen.main].compactMap { $0 }
    }

    private func applyMuteToAll() {
        windows.values.forEach { $0.setMuted(isMuted) }
    }
}

// MARK: - NSScreen helper

extension NSScreen {
    var screenID: CGDirectDisplayID {
        (deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID) ?? 0
    }
}
