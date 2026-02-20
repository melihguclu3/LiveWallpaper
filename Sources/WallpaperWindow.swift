import AppKit
import AVFoundation

/// Borderless window that sits below desktop icons.
final class WallpaperWindow: NSWindow {
    private var videoView: VideoPlayerView?
    private var gifView: GIFPlayerView?

    init(screen: NSScreen) {
        super.init(
            contentRect: screen.frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )

        // Place below desktop icons but above the wallpaper image
        level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopWindow)) + 1)

        collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        isOpaque = false
        backgroundColor = .black
        hasShadow = false
        ignoresMouseEvents = true
        isReleasedWhenClosed = false
    }

    // MARK: - Content

    func setContent(for source: MediaSource, muted: Bool) {
        clearContent()

        switch source {
        case .video(let url):
            let view = VideoPlayerView(frame: contentView!.bounds)
            view.autoresizingMask = [.width, .height]
            contentView?.addSubview(view)
            view.loadVideo(url: url)
            view.setMuted(muted)
            videoView = view

        case .gif(let url):
            let view = GIFPlayerView(frame: contentView!.bounds)
            view.autoresizingMask = [.width, .height]
            contentView?.addSubview(view)
            view.loadGIF(url: url)
            gifView = view
        }
    }

    func pauseContent() {
        videoView?.pause()
        gifView?.pause()
    }

    func resumeContent() {
        videoView?.play()
        gifView?.resume()
    }

    func stopContent() {
        videoView?.stop()
        gifView?.stop()
        clearContent()
    }

    func setMuted(_ muted: Bool) {
        videoView?.setMuted(muted)
    }

    func resizeContent() {
        videoView?.resizeLayer()
        gifView?.resizeLayer()
    }

    private func clearContent() {
        videoView?.removeFromSuperview()
        gifView?.removeFromSuperview()
        videoView = nil
        gifView = nil
    }
}
