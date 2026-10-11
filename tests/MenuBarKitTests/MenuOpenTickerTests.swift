import AppKit
import XCTest
@testable import MenuBarKit

@MainActor
final class MenuOpenTickerTests: XCTestCase {
    private func spin(_ mode: RunLoop.Mode, seconds: TimeInterval = 0.15) {
        RunLoop.main.run(mode: mode, before: Date().addingTimeInterval(seconds))
    }

    func test_firesWhileMenuTrackingRunLoopModeIsActive() {
        _ = NSApplication.shared // AppKit adds .eventTracking to the common modes
        let ticker = MenuOpenTicker()
        var ticks = 0
        ticker.start(interval: 0.01) { ticks += 1 }
        let deadline = Date().addingTimeInterval(2)
        while ticks == 0 && Date() < deadline {
            RunLoop.main.run(mode: .eventTracking, before: Date().addingTimeInterval(0.05))
        }
        ticker.stop()
        XCTAssertGreaterThan(ticks, 0)
    }

    func test_stopHaltsTicking() {
        let ticker = MenuOpenTicker()
        var ticks = 0
        ticker.start(interval: 0.01) { ticks += 1 }
        ticker.stop()
        XCTAssertFalse(ticker.isRunning)
        spin(.default)
        XCTAssertEqual(ticks, 0)
    }

    func test_startingTwiceReplacesTheFirstTimer() {
        let ticker = MenuOpenTicker()
        var first = 0
        var second = 0
        ticker.start(interval: 0.01) { first += 1 }
        ticker.start(interval: 0.01) { second += 1 }
        spin(.default)
        ticker.stop()
        XCTAssertEqual(first, 0)
        XCTAssertGreaterThan(second, 0)
    }
}
