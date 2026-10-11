import Foundation

/// The running app's version, as set by `package-app.sh` (`CFBundleShortVersionString`).
/// Development builds from `swift run`/tests have no bundle version.
public enum AppVersion {
    public static func string(bundle: Bundle = .main) -> String? {
        bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
    }

    /// "Version 1.4.0", or "Development build" when the bundle carries no version.
    public static func label(bundle: Bundle = .main) -> String {
        string(bundle: bundle).map { "Version \($0)" } ?? "Development build"
    }
}
