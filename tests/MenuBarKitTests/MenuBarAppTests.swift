import AppKit
import XCTest
@testable import MenuBarKit

@MainActor
final class MenuBarAppTests: XCTestCase {
    private final class Delegate: NSObject, NSApplicationDelegate {}

    func test_configureSetsDelegateAndAccessoryPolicy() {
        let app = NSApplication.shared
        let previousPolicy = app.activationPolicy()
        let previousDelegate = app.delegate
        addTeardownBlock { @MainActor in
            app.setActivationPolicy(previousPolicy)
            app.delegate = previousDelegate
        }
        let delegate = Delegate()
        configureMenuBarApp(app, delegate: delegate)
        XCTAssertTrue(app.delegate === delegate)
        XCTAssertEqual(app.activationPolicy(), .accessory)
    }
}
