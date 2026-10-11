import Foundation

/// Repeating timer for live-updating titles while an NSMenu is open. Menus run the event loop in
/// `.eventTracking` mode, so the timer is scheduled in `.common`.
@MainActor
public final class MenuOpenTicker {
    private var timer: Timer?

    public init() {}

    public var isRunning: Bool { timer != nil }

    public func start(interval: TimeInterval = 1, _ tick: @escaping @MainActor () -> Void) {
        stop()
        let timer = Timer(timeInterval: interval, repeats: true) { _ in
            MainActor.assumeIsolated { tick() }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    public func stop() {
        timer?.invalidate()
        timer = nil
    }
}
