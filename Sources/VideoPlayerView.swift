import AppKit
import AVFoundation

/// Hardware-accelerated video playback with seamless looping.
final class VideoPlayerView: NSView {
    private var player: AVQueuePlayer?
    private var playerLayer: AVPlayerLayer?
    private var looper: AVPlayerLooper?   // Must keep strong reference!

    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Public

    func loadVideo(url: URL) {
        cleanup()

        let asset = AVAsset(url: url)
        let item = AVPlayerItem(asset: asset)

        let queuePlayer = AVQueuePlayer()
        queuePlayer.automaticallyWaitsToMinimizeStalling = false

        // AVPlayerLooper handles gapless looping
        let playerLooper = AVPlayerLooper(player: queuePlayer, templateItem: item)

        let avLayer = AVPlayerLayer(player: queuePlayer)
        avLayer.videoGravity = .resizeAspectFill
        avLayer.frame = bounds
        layer?.addSublayer(avLayer)

        self.player = queuePlayer
        self.playerLayer = avLayer
        self.looper = playerLooper

        queuePlayer.play()
    }

    func play()  { player?.play() }
    func pause() { player?.pause() }

    func stop() {
        player?.pause()
        cleanup()
    }

    func setMuted(_ muted: Bool) {
        player?.isMuted = muted
    }

    func resizeLayer() {
        playerLayer?.frame = bounds
    }

    override func layout() {
        super.layout()
        playerLayer?.frame = bounds
    }

    // MARK: - Cleanup

    private func cleanup() {
        player?.pause()
        looper?.disableLooping()
        playerLayer?.removeFromSuperlayer()
        player = nil
        playerLayer = nil
        looper = nil
    }

    deinit { cleanup() }
}
