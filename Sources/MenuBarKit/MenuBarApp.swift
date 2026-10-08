import AppKit

@MainActor
public func configureMenuBarApp(_ app: NSApplication, delegate: NSApplicationDelegate) {
    app.delegate = delegate
    app.setActivationPolicy(.accessory)
}

/// Entry point for `main.swift`: `MainActor.assumeIsolated { runMenuBarApp(AppDelegate()) }`.
/// `NSApplication.delegate` is weak, so the delegate is kept alive for the lifetime of the run loop.
@MainActor
public func runMenuBarApp(_ delegate: NSApplicationDelegate) {
    let app = NSApplication.shared
    configureMenuBarApp(app, delegate: delegate)
    withExtendedLifetime(delegate) { app.run() }
}
