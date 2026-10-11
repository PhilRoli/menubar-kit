import AppKit
import XCTest
@testable import MenuBarKit

final class MenuItemsTests: XCTestCase {
    private final class Target: NSObject { @objc func go() {} }

    func test_itemSetsTitleSelectorKeyAndTarget() {
        let target = Target()
        let item = NSMenuItem.item("Refresh", action: #selector(Target.go), key: "r", target: target)
        XCTAssertEqual(item.title, "Refresh")
        XCTAssertEqual(item.action, #selector(Target.go))
        XCTAssertEqual(item.keyEquivalent, "r")
        XCTAssertTrue(item.target === target)
    }

    func test_itemKeyDefaultsToEmpty() {
        XCTAssertEqual(NSMenuItem.item("X", action: #selector(Target.go), target: Target()).keyEquivalent, "")
    }

    func test_infoIsEnabledActionlessAndKeepsAttributedTitle() {
        let title = NSAttributedString(string: "Hello", attributes: [.foregroundColor: NSColor.red])
        let item = NSMenuItem.info(title)
        XCTAssertEqual(item.title, "Hello")
        XCTAssertEqual(item.attributedTitle, title)
        XCTAssertNil(item.action)
        XCTAssertTrue(item.isEnabled)
        XCTAssertEqual(item.indentationLevel, 0)
    }

    func test_infoAppliesIndent() {
        XCTAssertEqual(NSMenuItem.info(NSAttributedString(string: "x"), indent: 1).indentationLevel, 1)
    }
}
