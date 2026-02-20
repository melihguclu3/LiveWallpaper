import SwiftUI
import AVFoundation

// MARK: - ViewModel

final class PopoverViewModel: ObservableObject {
    @Published var state: PlaybackState = .stopped
    @Published var fileName: String?
    @Published var isMuted: Bool = false
    @Published var showOnAllScreens: Bool = false
    @Published var launchAtLogin: Bool = false
    @Published var thumbnail: NSImage?
    @Published var youtubeURL: String = ""
    @Published var isDownloading: Bool = false
    @Published var downloadError: String?

    private let manager = WallpaperManager.shared

    init() {
        sync()
        manager.onStateChange = { [weak self] in
            DispatchQueue.main.async { self?.sync() }
        }
    }

    func sync() {
        state = manager.state
        fileName = manager.currentFileName
        isMuted = manager.isMuted
        showOnAllScreens = manager.showOnAllScreens
        launchAtLogin = LaunchAtLogin.isEnabled
    }

    // MARK: - Actions

    func chooseVideo() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.movie, .mpeg4Movie, .quickTimeMovie, .avi]
        panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let url = panel.url else { return }
        manager.play(source: .video(url))
        generateThumbnail(for: .video(url))
    }

    func chooseGIF() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.gif]
        panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let url = panel.url else { return }
        manager.play(source: .gif(url))
        generateThumbnail(for: .gif(url))
    }

    func togglePlayPause() {
        switch state {
        case .playing: manager.pause()
        case .paused:  manager.resume()
        case .stopped: break
        }
    }

    func stop() { manager.stop(); thumbnail = nil }
    func quit() { manager.stop(); NSApp.terminate(nil) }

    func setMuted(_ val: Bool) {
        manager.isMuted = val
        sync()
    }

    func setAllScreens(_ val: Bool) {
        manager.showOnAllScreens = val
        sync()
    }

    func setLaunchAtLogin(_ val: Bool) {
        LaunchAtLogin.toggle()
        sync()
    }

    func downloadYouTube() {
        let urlString = youtubeURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !urlString.isEmpty else { return }

        guard YouTubeService.isYtDlpAvailable() else {
            downloadError = L10n.string("ytdlp_install_hint")
            return
        }

        isDownloading = true
        downloadError = nil

        let service = YouTubeService()
        service.download(urlString: urlString) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isDownloading = false
                switch result {
                case .success(let fileURL):
                    self.youtubeURL = ""
                    self.manager.play(source: .video(fileURL))
                    self.generateThumbnail(for: .video(fileURL))
                case .failure(let error):
                    self.downloadError = error.localizedDescription
                }
            }
        }
    }

    // MARK: - Thumbnail

    func generateThumbnail(for source: MediaSource) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let image: NSImage?
            switch source {
            case .video(let url):
                image = Self.videoThumbnail(url: url)
            case .gif(let url):
                image = NSImage(contentsOf: url)
            }
            DispatchQueue.main.async { self?.thumbnail = image }
        }
    }

    private static func videoThumbnail(url: URL) -> NSImage? {
        let asset = AVAsset(url: url)
        let gen = AVAssetImageGenerator(asset: asset)
        gen.appliesPreferredTrackTransform = true
        gen.maximumSize = CGSize(width: 640, height: 360)
        let time = CMTime(seconds: 1, preferredTimescale: 600)
        guard let cg = try? gen.copyCGImage(at: time, actualTime: nil) else { return nil }
        return NSImage(cgImage: cg, size: NSSize(width: cg.width, height: cg.height))
    }

    // Restore thumbnail on launch
    func restoreThumbnail() {
        if let source = manager.currentSource {
            generateThumbnail(for: source)
        }
    }
}

// MARK: - PopoverView

struct PopoverView: View {
    @StateObject private var vm = PopoverViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            header
            preview
            sourceButtons
            youtubeRow
            Divider()
            toggles
            Divider()
            bottomBar
        }
        .padding(14)
        .frame(width: 320)
        .onAppear { vm.restoreThumbnail() }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text("LiveWallpaper")
                    .font(.system(size: 14, weight: .semibold))
                Spacer()
                Text(statusText)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            if let name = vm.fileName {
                Text("\(L10n.string("selected_prefix")) \(name)")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
        }
    }

    private var statusText: String {
        switch vm.state {
        case .playing: return L10n.string("playing")
        case .paused:  return L10n.string("paused")
        case .stopped: return L10n.string("stopped")
        }
    }

    // MARK: - Preview

    private var preview: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(.black.opacity(0.3))

            if let img = vm.thumbnail {
                Image(nsImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Text(L10n.string("no_video"))
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(height: 140)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    // MARK: - Source Buttons

    private var sourceButtons: some View {
        HStack(spacing: 8) {
            Button(L10n.string("choose_video")) { vm.chooseVideo() }
                .controlSize(.small)

            Button(L10n.string("choose_gif")) { vm.chooseGIF() }
                .controlSize(.small)

            Spacer()

            if vm.state == .playing {
                Button(L10n.string("pause")) { vm.togglePlayPause() }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
            } else if vm.state == .paused {
                Button(L10n.string("play")) { vm.togglePlayPause() }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
            }
        }
    }

    // MARK: - YouTube

    private var youtubeRow: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                TextField("YouTube URL...", text: $vm.youtubeURL)
                    .textFieldStyle(.roundedBorder)
                    .controlSize(.small)
                    .onSubmit { vm.downloadYouTube() }

                if vm.isDownloading {
                    ProgressView()
                        .controlSize(.small)
                        .frame(width: 16, height: 16)
                } else {
                    Button(L10n.string("download")) { vm.downloadYouTube() }
                        .controlSize(.small)
                        .disabled(vm.youtubeURL.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            if let err = vm.downloadError {
                Text(err)
                    .font(.system(size: 10))
                    .foregroundStyle(.red)
                    .lineLimit(2)
            }
        }
    }

    // MARK: - Toggles

    private var toggles: some View {
        VStack(alignment: .leading, spacing: 6) {
            Toggle(L10n.string("show_all_screens"), isOn: Binding(
                get: { vm.showOnAllScreens },
                set: { vm.setAllScreens($0) }
            ))
            .toggleStyle(.checkbox)

            Toggle(L10n.string("muted"), isOn: Binding(
                get: { vm.isMuted },
                set: { vm.setMuted($0) }
            ))
            .toggleStyle(.checkbox)

            Toggle(L10n.string("launch_at_login"), isOn: Binding(
                get: { vm.launchAtLogin },
                set: { vm.setLaunchAtLogin($0) }
            ))
            .toggleStyle(.checkbox)
        }
        .font(.system(size: 13))
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        HStack {
            Button(L10n.string("stop")) { vm.stop() }
                .controlSize(.small)
                .disabled(vm.state == .stopped)
            Spacer()
            Button(L10n.string("quit")) { vm.quit() }
                .controlSize(.small)
        }
    }
}

// MARK: - Localization additions

extension PopoverView {
    // "no_video" and "download" keys are already in Localizable.strings
}
