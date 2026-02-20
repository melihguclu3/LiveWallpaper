import Foundation

/// Simple localization helper.
enum L10n {
    static func string(_ key: String) -> String {
        NSLocalizedString(key, comment: "")
    }
}
