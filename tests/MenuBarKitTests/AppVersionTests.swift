import AppKit
import XCTest
@testable import MenuBarKit

@MainActor
final class AppVersionTests: XCTestCase {
    private func bundle(version: String?) throws -> Bundle {
        let name = "AppVersionTests-\(UUID().uuidString).app"
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(name)
        let contents = root.appendingPathComponent("Contents")
        try FileManager.default.createDirectory(at: contents, withIntermediateDirectories: true)
        addTeardownBlock { try? FileManager.default.removeItem(at: root) }
        var plist: [String: Any] = ["CFBundleIdentifier": "com.example.test"]
        if let version { plist["CFBundleShortVersionString"] = version }
        try (plist as NSDictionary).write(to: contents.appendingPathComponent("Info.plist"))
        return try XCTUnwrap(Bundle(url: root))
    }

    func test_stringReadsShortVersion() throws {
        XCTAssertEqual(AppVersion.string(bundle: try bundle(version: "1.4.0")), "1.4.0")
    }

    func test_stringKeepsPrereleaseSuffix() throws {
        XCTAssertEqual(AppVersion.string(bundle: try bundle(version: "1.2.3-rc.1")), "1.2.3-rc.1")
    }

    func test_stringIsNilWithoutVersion() throws {
        XCTAssertNil(AppVersion.string(bundle: try bundle(version: nil)))
    }

    func test_labelFormatsVersionOrFallsBack() throws {
        XCTAssertEqual(AppVersion.label(bundle: try bundle(version: "1.4.0")), "Version 1.4.0")
        XCTAssertEqual(AppVersion.label(bundle: try bundle(version: nil)), "Development build")
    }

    func test_versionLabelIsSmallSecondaryText() throws {
        let label = PreferencesLayout.versionLabel(bundle: try bundle(version: "2.0.1"))
        XCTAssertEqual(label.stringValue, "Version 2.0.1")
        XCTAssertEqual(label.font, .systemFont(ofSize: 11))
        XCTAssertEqual(label.textColor, .secondaryLabelColor)
        XCTAssertTrue(label.isSelectable)
    }
}
