import AppKit
import XCTest
@testable import MenuBarKit

final class MainMenuTests: XCTestCase {
    func test_quitItemUsesAppName() {
        let menu = MainMenu.make(appName: "RunPulse")
        let appMenu = menu.items[0].submenu
        XCTAssertEqual(appMenu?.items.map(\.title), ["Close Window", "Quit RunPulse"])
        XCTAssertEqual(appMenu?.items.map(\.keyEquivalent), ["w", "q"])
    }

    func test_editMenuHasStandardTextShortcuts() {
        let edit = MainMenu.make(appName: "X").items[1].submenu
        XCTAssertEqual(edit?.title, "Edit")
        XCTAssertEqual(edit?.items.map(\.title), ["Cut", "Copy", "Paste", "Select All"])
        XCTAssertEqual(edit?.items.map(\.keyEquivalent), ["x", "c", "v", "a"])
        XCTAssertEqual(edit?.items.map(\.action), [
            #selector(NSText.cut(_:)), #selector(NSText.copy(_:)),
            #selector(NSText.paste(_:)), #selector(NSText.selectAll(_:))
        ])
    }
}
