import Foundation

/// UserDefaults wrapper for app settings.
enum Defaults {
    private static let ud = UserDefaults.standard

    static var isMuted: Bool {
        get { ud.bool(forKey: "isMuted") }
        set { ud.set(newValue, forKey: "isMuted") }
    }

    static var showOnAllScreens: Bool {
        get { ud.bool(forKey: "showOnAllScreens") }
        set { ud.set(newValue, forKey: "showOnAllScreens") }
    }

    static var lastSourceURL: URL? {
        get {
            guard let s = ud.string(forKey: "lastSourceURL") else { return nil }
            return URL(fileURLWithPath: s)
        }
        set { ud.set(newValue?.path, forKey: "lastSourceURL") }
    }

    static var lastSourceType: String {
        get { ud.string(forKey: "lastSourceType") ?? "video" }
        set { ud.set(newValue, forKey: "lastSourceType") }
    }
}
