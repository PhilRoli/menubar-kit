import AppKit

/// Calls `handler` on the main actor whenever the Mac wakes from sleep. The caller keeps the returned token
/// and removes it with `NSWorkspace.shared.notificationCenter.removeObserver(_:)`.
public func observeWake(_ handler: @escaping @MainActor () -> Void) -> NSObjectProtocol {
    NSWorkspace.shared.notificationCenter.addObserver(
        forName: NSWorkspace.didWakeNotification, object: nil, queue: .main
    ) { _ in
        MainActor.assumeIsolated { handler() }
    }
}
