import Foundation

/// Downloads YouTube videos via yt-dlp CLI tool.
final class YouTubeService {
    private var process: Process?
    private static let cacheDir: URL = {
        let dir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("com.melih.LiveWallpaper/YouTube", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    // MARK: - Check availability

    static func isYtDlpAvailable() -> Bool {
        ytDlpPath() != nil
    }

    private static func ytDlpPath() -> String? {
        // Check common install locations
        let candidates = [
            "/opt/homebrew/bin/yt-dlp",
            "/usr/local/bin/yt-dlp",
            "/usr/bin/yt-dlp",
        ]
        for path in candidates {
            if FileManager.default.isExecutableFile(atPath: path) { return path }
        }

        // Fallback: ask shell
        let task = Process()
        let pipe = Pipe()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        task.arguments = ["yt-dlp"]
        task.standardOutput = pipe
        task.standardError = FileHandle.nullDevice
        try? task.run()
        task.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let path = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let path, !path.isEmpty, FileManager.default.isExecutableFile(atPath: path) {
            return path
        }
        return nil
    }

    // MARK: - Download

    func download(urlString: String, completion: @escaping (Result<URL, Error>) -> Void) {
        guard let ytdlp = Self.ytDlpPath() else {
            completion(.failure(YTError.ytDlpNotFound))
            return
        }

        let outputTemplate = Self.cacheDir
            .appendingPathComponent("%(id)s.%(ext)s").path

        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: ytdlp)
        proc.arguments = [
            urlString,
            "-f", "bestvideo[height<=1080][ext=mp4]+bestaudio[ext=m4a]/best[height<=1080][ext=mp4]/best",
            "--merge-output-format", "mp4",
            "-o", outputTemplate,
            "--no-playlist",
            "--no-warnings",
        ]

        let errPipe = Pipe()
        let outPipe = Pipe()
        proc.standardOutput = outPipe
        proc.standardError = errPipe
        self.process = proc

        proc.terminationHandler = { [weak self] p in
            self?.process = nil

            if p.terminationStatus == 0 {
                // Find the downloaded file (most recent mp4 in cache)
                if let file = Self.mostRecentFile(in: Self.cacheDir) {
                    completion(.success(file))
                } else {
                    completion(.failure(YTError.fileNotFound))
                }
            } else {
                let errData = errPipe.fileHandleForReading.readDataToEndOfFile()
                let errMsg = String(data: errData, encoding: .utf8) ?? "Unknown error"
                completion(.failure(YTError.downloadFailed(errMsg)))
            }
        }

        do {
            try proc.run()
        } catch {
            completion(.failure(error))
        }
    }

    func cancel() {
        process?.terminate()
        process = nil
    }

    // MARK: - Helpers

    private static func mostRecentFile(in dir: URL) -> URL? {
        let fm = FileManager.default
        guard let files = try? fm.contentsOfDirectory(
            at: dir, includingPropertiesForKeys: [.contentModificationDateKey]
        ) else { return nil }

        return files
            .filter { $0.pathExtension == "mp4" || $0.pathExtension == "webm" || $0.pathExtension == "mkv" }
            .sorted {
                let d1 = (try? $0.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? .distantPast
                let d2 = (try? $1.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? .distantPast
                return d1 > d2
            }
            .first
    }

    // MARK: - Errors

    enum YTError: LocalizedError {
        case ytDlpNotFound
        case fileNotFound
        case downloadFailed(String)

        var errorDescription: String? {
            switch self {
            case .ytDlpNotFound:       return "yt-dlp not found. Install with: brew install yt-dlp"
            case .fileNotFound:        return "Downloaded file not found."
            case .downloadFailed(let m): return "Download failed: \(m)"
            }
        }
    }
}
