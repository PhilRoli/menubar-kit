import AppKit
import XCTest
@testable import MenuBarKit

@MainActor
final class WakeObserverTests: XCTestCase {
    func test_handlerRunsOnWakeNotificationOnMainThread() {
        var calls = 0
        var onMain = false
        let token = observeWake {
            calls += 1
            onMain = Thread.isMainThread
        }
        NSWorkspace.shared.notificationCenter.post(name: NSWorkspace.didWakeNotification, object: nil)
        NSWorkspace.shared.notificationCenter.removeObserver(token)
        XCTAssertEqual(calls, 1)
        XCTAssertTrue(onMain)
    }

    func test_removedObserverIsNotCalled() {
        var calls = 0
        let token = observeWake { calls += 1 }
        NSWorkspace.shared.notificationCenter.removeObserver(token)
        NSWorkspace.shared.notificationCenter.post(name: NSWorkspace.didWakeNotification, object: nil)
        XCTAssertEqual(calls, 0)
    }
}
