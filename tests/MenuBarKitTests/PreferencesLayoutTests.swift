import AppKit
import XCTest
@testable import MenuBarKit

@MainActor
final class PreferencesLayoutTests: XCTestCase {
    func test_sectionLabelIsSmallSemibold() {
        let label = PreferencesLayout.sectionLabel("General")
        XCTAssertEqual(label.stringValue, "General")
        XCTAssertEqual(label.font, .systemFont(ofSize: 11, weight: .semibold))
    }

    func test_labelIsRegular13() {
        XCTAssertEqual(PreferencesLayout.label("Name").font, .systemFont(ofSize: 13))
    }

    func test_separatorIsSeparatorBoxWithGivenWidth() throws {
        let box = try XCTUnwrap(PreferencesLayout.separator(width: 380) as? NSBox)
        XCTAssertEqual(box.boxType, .separator)
        XCTAssertFalse(box.translatesAutoresizingMaskIntoConstraints)
        XCTAssertEqual(box.constraints.first { $0.firstAttribute == .width }?.constant, 380)
    }

    func test_pinAndFitPinsStackToContentViewAndSizesWindow() throws {
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 50, height: 50),
                              styleMask: [.titled], backing: .buffered, defer: true)
        let stack = NSStackView(views: [
            PreferencesLayout.label("Hello world"), PreferencesLayout.separator(width: 300)
        ])
        stack.orientation = .vertical
        stack.edgeInsets = NSEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)

        PreferencesLayout.pinAndFit(stack, in: window)

        let content = try XCTUnwrap(window.contentView)
        XCTAssertTrue(stack.superview === content)
        XCTAssertFalse(stack.translatesAutoresizingMaskIntoConstraints)
        XCTAssertEqual(content.frame.size.width, stack.fittingSize.width, accuracy: 1)
        XCTAssertEqual(content.frame.size.height, stack.fittingSize.height, accuracy: 1)
    }
}
