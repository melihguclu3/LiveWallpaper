import AppKit
import ImageIO

/// Animated GIF playback using Core Animation.
final class GIFPlayerView: NSView {
    private var animationLayer: CALayer?
    private static let animationKey = "gifAnimation"

    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Public

    func loadGIF(url: URL) {
        cleanup()

        guard let data = try? Data(contentsOf: url),
              let source = CGImageSourceCreateWithData(data as CFData, nil) else { return }

        let count = CGImageSourceGetCount(source)
        guard count > 0 else { return }

        var images: [CGImage] = []
        var durations: [TimeInterval] = []

        for i in 0..<count {
            guard let cgImage = CGImageSourceCreateImageAtIndex(source, i, nil) else { continue }
            images.append(cgImage)

            let props = CGImageSourceCopyPropertiesAtIndex(source, i, nil) as? [String: Any]
            let gifProps = props?[kCGImagePropertyGIFDictionary as String] as? [String: Any]
            let delay = (gifProps?[kCGImagePropertyGIFUnclampedDelayTime as String] as? Double)
                ?? (gifProps?[kCGImagePropertyGIFDelayTime as String] as? Double)
                ?? 0.1
            durations.append(max(delay, 0.02)) // Floor at 20ms
        }

        guard !images.isEmpty else { return }

        let totalDuration = durations.reduce(0, +)

        // Build cumulative key times (0.0 ... 1.0)
        var keyTimes: [NSNumber] = [0.0]
        var cumulative: TimeInterval = 0
        for d in durations.dropLast() {
            cumulative += d
            keyTimes.append(NSNumber(value: cumulative / totalDuration))
        }

        let gifLayer = CALayer()
        gifLayer.frame = bounds
        gifLayer.contentsGravity = .resizeAspectFill
        gifLayer.contents = images.first
        layer?.addSublayer(gifLayer)

        let animation = CAKeyframeAnimation(keyPath: "contents")
        animation.values = images
        animation.keyTimes = keyTimes
        animation.duration = totalDuration
        animation.repeatCount = .infinity
        animation.calculationMode = .discrete
        animation.isRemovedOnCompletion = false
        gifLayer.add(animation, forKey: Self.animationKey)

        animationLayer = gifLayer
    }

    func pause() {
        guard let l = animationLayer else { return }
        let pausedTime = l.convertTime(CACurrentMediaTime(), from: nil)
        l.speed = 0
        l.timeOffset = pausedTime
    }

    func resume() {
        guard let l = animationLayer else { return }
        let pausedTime = l.timeOffset
        l.speed = 1
        l.timeOffset = 0
        l.beginTime = 0
        l.beginTime = l.convertTime(CACurrentMediaTime(), from: nil) - pausedTime
    }

    func stop() { cleanup() }

    func resizeLayer() {
        animationLayer?.frame = bounds
    }

    override func layout() {
        super.layout()
        animationLayer?.frame = bounds
    }

    // MARK: - Cleanup

    private func cleanup() {
        animationLayer?.removeAllAnimations()
        animationLayer?.removeFromSuperlayer()
        animationLayer = nil
    }

    deinit { cleanup() }
}
